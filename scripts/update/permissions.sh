#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;
master=$(cut -d: -f1 < /root/.master.info)
if [[ -f /install/.plex.lock ]]; then
    if ! groups plex | grep -q "${master}"; then
        echo_progress_start "Adding ${master} to plex group"
        usermod -a -G "${master}" plex
        echo_progress_done
    fi
fi

# shellcheck disable=SC2016 # literal text matched in the target file, expansion not wanted
if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.profile; then
    # shellcheck disable=SC2016 # literal text matched in the target file, expansion not wanted
    sed -i '/export PATH=$PATH:\/usr\/local\/bin\/swizzin/d' /root/.profile
fi

# shellcheck disable=SC2016 # literal text matched in the target file, expansion not wanted
if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.bashrc; then
    :
else
    # shellcheck disable=SC2016 # literal line written to the target file, expansion not wanted
    echo 'export PATH=$PATH:/usr/local/bin/swizzin' >> /root/.bashrc
fi

# Ensure .config dir is correctly owned
if [[ -e /home/${master}/.config ]]; then
    # TODO do for all users maybe?
    perm=$(stat -c '%U' /home/"${master}"/.config)
    if [[ ! "$perm" == "${master}" ]]; then
        echo_progress_start "Fixing ownership of master's .config dir"
        chown -R "${master}": /home/"${master}"/.config
        echo_progress_done
    fi
fi
