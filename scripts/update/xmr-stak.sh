#!/bin/bash
#xmr-stak upgrade to xmrig

if [[ -f /install/.xmr-stak.lock ]]; then
    if [[ ! -f /install/.xmrig.lock ]]; then
        user=$(cat /root/.master.info | cut -d: -f1)
        # shellcheck disable=SC2154 # log is set by box/globals.sh
        systemctl disable -q --now xmr >> "$log" 2>&1
        echo_info "Deprecated package 'xmr-stak' detected. Package 'xmr-stak' will be replaced with 'xmrig'"
        read -r -p "Press enter to continue"
        address=$(grep -oP "pool_address\" : \"\K[^\"]+" "/home/${user}/.xmr/pools.txt")
        export address
        wallet=$(grep -oP "wallet_address\" : \"\K[^\"]+" "/home/${user}/.xmr/pools.txt")
        export wallet
        password=$(hostname)
        export password
        echo_info "Setup has detected the following variables:
pool_address: ${address}
wallet: ${wallet}"
        if ! ask "Is this correct?"; then
            export address=
            export wallet=
            echo_info "xmrig installer will ask for new values."
        fi

        echo_info "Installing xmrig"
        bash /usr/local/bin/swizzin/install/xmrig.sh
        echo_info "Uninstalling xmrstak"
        bash /usr/local/bin/swizzin/remove/xmr-stak.sh
    else
        :
    fi
fi
