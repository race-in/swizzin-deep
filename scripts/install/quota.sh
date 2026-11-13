#!/bin/bash
#
# [Quick Box :: Install User Quotas]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

green=$(tput setaf 2)
yellow=$(tput setaf 3)
bold=$(tput bold)
normal=$(tput sgr0)

echo
echo "##################################################################################"
echo "#${bold} By default the quota script will use ${green}/${normal} ${bold}as the${normal}"
echo "#${bold} primary partition for mounting quotas.${normal}"
echo "#"
echo "#${bold} Some providers, such as OVH and SYS force ${green}/home${normal} ${bold}as the primary mount ${normal}"
echo "#${bold} on their server setups. So if you have an OVH or SYS server and have not"
echo "#${bold} modified your partitions, it is safe to choose option ${yellow}2)${normal} ${bold}below.${normal}"
echo "#"
echo "#${bold} If you are not sure:${normal}"
echo "#${bold} I have listed out your current partitions below. Your mountpoint will be"
echo "#${bold} listed as ${green}/home${normal} ${bold}or ${green}/${normal}${bold}. ${normal}"
echo "#"
echo "#${bold} Typically, the partition with the most space assigned is your default.${normal}"
echo "##################################################################################"
echo
lsblk
echo
echo -e "${bold}${yellow}1)${normal} / - ${green}root mount${normal}"
echo -e "${bold}${yellow}2)${normal} /home - ${green}home mount${normal}"
echo -ne "${bold}${yellow}What is your mount point for user quotas?${normal} (Default ${green}1${normal}): "
read -r version
case $version in
    1 | "") primaryroot=root ;;
    2) primaryroot=home ;;
    *) primaryroot=root ;;
esac
echo "Using ${green}$primaryroot mount${normal} for quotas"
echo

function _installquota() {
    #TODO why are we installing the quota package twice?
    apt_install quota
    if [[ ${primaryroot} == "root" ]]; then
        loc=$(echo -e "/\t")
        loc2="/ "
    elif [[ ${primaryroot} == "home" ]]; then
        loc=$(echo -e "/home\t")
        loc2="/home "
    fi
    hook=$(grep "${loc}" /etc/fstab)
    hook2=$(grep "${loc2}" /etc/fstab)

    if [[ -z $hook ]]; then
        if [[ -z $hook2 ]]; then
            echo "ERROR: Cannot determine $primaryroot mount point. Installer cannot continue."
            exit 1
        fi
        hook=$hook2
        loc=$loc2
    fi

    if echo "$hook" | grep -q "defaults"; then
        hook=defaults
    elif echo "$hook" | grep -q "errors=remount-ro"; then
        hook=errors=remount-ro
    else
        echo "ERROR: Could not find a hook in /etc/fstab for quotas to install to. Quota requires either defaults or errors=remount-ro to be present as a mount option for the intended quota partition."
        exit 1
    fi

    echo "Installing dependencies"
    if [[ $DISTRO == Ubuntu ]]; then
        # shellcheck disable=SC1003 # the backslash is part of the sed address, not an escaped quote
        sed -ie '/\'"${loc}"'/ s/'${hook}'/'${hook}',usrjquota=aquota.user,jqfmt=vfsv1/' /etc/fstab
        apt_install linux-image-extra-virtual quota
        # shellcheck disable=SC2129 # separate redirects keep per-command failure isolation
        # shellcheck disable=SC2086 # loc's trailing tab is meant to be stripped by word splitting
        # shellcheck disable=SC2154 # log is set by scripts/box
        mount -o remount ${loc} >> "${log}" 2>&1
        quotacheck -auMF vfsv1 >> "${log}" 2>&1
        quotaon -uv / >> "${log}" 2>&1
        systemctl start quota >> "${log}" 2>&1
    elif [[ $DISTRO == Debian ]]; then
        # shellcheck disable=SC1003 # the backslash is part of the sed address, not an escaped quote
        sed -ie '/\'"${loc}"'/ s/'${hook}'/'${hook}',usrjquota=aquota.user,jqfmt=vfsv1/' /etc/fstab
        apt_install quota
        # shellcheck disable=SC2129 # separate redirects keep per-command failure isolation
        # shellcheck disable=SC2086 # loc's trailing tab is meant to be stripped by word splitting
        # shellcheck disable=SC2154 # log is set by scripts/box
        mount -o remount ${loc} >> "${log}" 2>&1
        quotacheck -auMF vfsv1 >> "${log}" 2>&1
        quotaon -uv / >> "${log}" 2>&1
        systemctl start quota >> "${log}" 2>&1
    fi

    if [[ -d /srv/rutorrent ]]; then
        #shellcheck source=sources/functions/rutorrent
        . /etc/swizzin/sources/functions/rutorrent
        rutorrent_fix_quota
    fi
}

DISTRO=$(lsb_release -is)

_installquota

cat > /etc/sudoers.d/quota << EOSUD
#Defaults  env_keep -="HOME"
Defaults:www-data !logfile
Defaults:www-data !syslog
Defaults:www-data !pam_session

Cmnd_Alias   QUOTA = /usr/bin/quota

www-data     ALL = (ALL) NOPASSWD: QUOTA
EOSUD

touch /install/.quota.lock
echo "${primaryroot}" > /install/.quota.lock

echo "Quotas have been installed. Use the command setdisk to set quotas per user."
