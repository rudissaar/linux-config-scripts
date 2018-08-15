#!/usr/bin/env bash

MINETEST_PORT=30000

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf install -y \
	minetest \
	minetest-server

# Change Port if you specified new one.
if [[ "${MINETEST_PORT}" != '30000' ]]; then
    sed -i '/^PORT=30000/s/30000/'${MINETEST_PORT}'/' /etc/sysconfig/minetest/default.conf
fi

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" = '1' ]]; then
    # Make sure firewalld is installed.
    dnf install -y firewalld

    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --add-port=${MINETEST_PORT}/udp
    firewall-cmd --runtime-to-permanent
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo "firewall-cmd --add-port=${MINETEST_PORT}/udp"
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Enable Minetest service.
systemctl start minetest@default
systemctl enable minetest@default
