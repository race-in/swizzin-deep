#!/bin/bash

if [[ -f /install/.headphones.lock ]]; then
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/${user}/.headphones ]]; then
        if ! apt-cache show python2.7-dev > /dev/null 2>&1; then
            echo_warn "python2.7 is not available on this release, skipping the legacy Headphones migration."
            exit 0
        fi
        echo_progress_start "Updating Headphones to use python virtualenv"
        active=$(systemctl is-active headphones)
        codename=$(lsb_release -cs)
        #shellcheck source=sources/functions/pyenv
        . /etc/swizzin/sources/functions/pyenv
        systemctl stop headphones
        if [[ $codename = "buster" ]]; then
            LIST='git python2.7-dev virtualenv python-virtualenv python-pip'
        else
            LIST='git python2.7-dev'
        fi
        # shellcheck disable=SC2086 # LIST is a space-separated package list, splitting is intentional
        apt_install $LIST

        if [[ ! $codename = "buster" ]]; then
            python_getpip
        fi

        python2_venv "${user}" headphones

        PIP='wheel cheetah asn1'
        # shellcheck disable=SC2086 # PIP is a space-separated package list, splitting is intentional
        /opt/.venv/headphones/bin/pip install $PIP >> "${log}" 2>&1
        chown -R "${user}": /opt/.venv/headphones

        mv "/home/${user}/.headphones" /opt/headphones

        cat > /etc/systemd/system/headphones.service << HEADSD
[Unit]
Description=Headphones
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/headphones/bin/python2 /opt/headphones/Headphones.py -d --pidfile /run/${user}/headphones.pid --datadir /opt/headphones --nolaunch --config /opt/headphones/config.ini --port 8004
PIDFile=/run/${user}/headphones.pid


[Install]
WantedBy=multi-user.target
HEADSD
        systemctl daemon-reload
        sed -i "s|/home/${user}/.headphones|/opt/headphones|g" /opt/headphones/config.ini

        if [[ $active == "active" ]]; then
            systemctl enable -q --now headphones 2>&1 | tee -a "$log"
        fi
    fi
    echo_progress_done

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q 'http_proxy = 1' /opt/headphones/config.ini; then
            echo_progress_start "Updating Headphones nginx"
            sed -i 's/http_proxy = 1/http_proxy = 0/g' /opt/headphones/config.ini
            systemctl try-restart headphones
            echo_progress_done
        fi
    fi
fi
