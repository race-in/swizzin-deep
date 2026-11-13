#!/bin/bash

rm -rf /opt/.venv/calibreweb
rm -rf /opt/calibreweb

systemctl disable --now -q calibreweb
rm /etc/systemd/system/calibreweb.service
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibreweb.conf
    systemctl reload nginx
fi

# shellcheck disable=SC2154 # log is exported by box from sources/globals.sh
userdel calibreweb -f -r >> "$log" 2>&1

if [ ! -f /install/.calibrecs.lock ] && [ ! -f /install/.calibre.lock ]; then
    echo_log_only "Clearing calibre swizdb"
    swizdb clear calibre/library_path
    swizdb clear calibre/library_user
fi

rm /install/.calibreweb.lock
