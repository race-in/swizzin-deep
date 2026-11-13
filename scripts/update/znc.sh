#!/bin/bash

if [[ -f /install/.znc.lock ]]; then
    #shellcheck source=sources/functions/letsencrypt
    . /etc/swizzin/sources/functions/letsencrypt
    le_znc_hook

    if [[ ! -s /install/.znc.lock ]]; then
        echo_progress_start "Updating ZNC config"
        grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//' > /install/.znc.lock
        grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//' >> /install/.znc.lock
        echo_progress_done
    fi
fi
