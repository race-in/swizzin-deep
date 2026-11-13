#!/bin/bash
echo_log_only "Removing Transmission"
mapfile -t users < <(cut -d: -f1 < /etc/htpasswd)
for u in ${users[@]}; do
    echo_log_only "Shutting down transmission@$u"
    # shellcheck disable=SC2154 # log is exported by box from sources/globals.sh
    systemctl stop transmission@"$u" >> "$log" 2>&1
    systemctl disable transmission@"$u" >> "$log" 2>&1
    rm -f "/home/${u}/.config/transmission-daemon/settings.json"
done

add-apt-repository --remove ppa:transmissionbt/ppa -y >> "$log" 2>&1
apt_remove --purge transmission-common transmission-cli transmission-daemon
echo_log_only "Removing service file and nginx configs"
rm /etc/systemd/system/transmission@.service
{
    rm /etc/nginx/apps/transmission.conf
    rm /etc/nginx/conf.d/*.transmission.conf
    systemctl reload nginx
} >> "$log" 2>&1
systemctl daemon-reload

rm /install/.transmission.lock
