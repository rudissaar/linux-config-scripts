#!/usr/bin/env bash
# Script that simplifies installing Minetest server on Fedora GNU/Linux.
# This script also provides you with options to install latest mods from Github.

MINETEST_PORT=30000

MINETEST_MOD_MOREBLOCKS=0
MINETEST_MOD_MOREORES=0
MINETEST_MOD_TORCHES=0

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

GET_LATEST_RELEASE () {
    URL="$(curl -s "https://api.github.com/repos/${1}/tags" | jq .[0].tarball_url | tr -d '"')"
    DESTINATION="/tmp/$(echo "${1}" | tr '/' '-').tar.gz"
    wget "${URL}" -O "${DESTINATION}"
}

# Install packages.
dnf install -y \
    minetest \
    minetest-server \
    curl \
    wget \
    jq

# Install mods.
if [[ "${MINETEST_MOD_MOREBLOCKS}" == '1' ]]; then
    MOD_REPO='minetest-mods/moreblocks'
    GET_LATEST_RELEASE "${MOD_REPO}"
    TARBALL="/tmp/$(echo ${MOD_REPO} | tr '/' '-').tar.gz"

    if [[ -f "${TARBALL}" ]]; then
        tar -xf "${TARBALL}" -C '/tmp'

        if [[ ! -d '/usr/share/minetest/games/minetest_game/mods/moreblocks' ]]; then
            mkdir -p '/usr/share/minetest/games/minetest_game/mods/moreblocks'
        fi

        cp -r "/tmp/$(echo ${MOD_REPO} | tr '/' '-')-"*/* /usr/share/minetest/games/minetest_game/mods/moreblocks/
        rm -rf "/tmp/$(echo ${MOD_REPO} | tr '/' '-')"*
    fi
fi

if [[ "${MINETEST_MOD_MOREORES}" == '1' ]]; then
    MOD_REPO='minetest-mods/moreores'
    GET_LATEST_RELEASE "${MOD_REPO}"
    TARBALL="/tmp/$(echo ${MOD_REPO} | tr '/' '-').tar.gz"

    if [[ -f "${TARBALL}" ]]; then
        tar -xf "${TARBALL}" -C '/tmp'

        if [[ ! -d '/usr/share/minetest/games/minetest_game/mods/moreores' ]]; then
            mkdir -p '/usr/share/minetest/games/minetest_game/mods/moreores'
        fi

        cp -r "/tmp/$(echo ${MOD_REPO} | tr '/' '-')-"*/* /usr/share/minetest/games/minetest_game/mods/moreores/
        rm -rf "/tmp/$(echo ${MOD_REPO} | tr '/' '-')"*
    fi
fi

if [[ "${MINETEST_MOD_TORCHES}" == '1' ]]; then
    MOD_REPO='minetest-mods/torches'
    GET_LATEST_RELEASE "${MOD_REPO}"
    TARBALL="/tmp/$(echo ${MOD_REPO} | tr '/' '-').tar.gz"

    if [[ -f "${TARBALL}" ]]; then
        tar -xf "${TARBALL}" -C '/tmp'

        if [[ ! -d '/usr/share/minetest/games/minetest_game/mods/torches' ]]; then
            mkdir -p '/usr/share/minetest/games/minetest_game/mods/torches'
        fi

        cp -r "/tmp/$(echo ${MOD_REPO} | tr '/' '-')-"*/* /usr/share/minetest/games/minetest_game/mods/torches/
        rm -rf "/tmp/$(echo ${MOD_REPO} | tr '/' '-')"*
    fi
fi

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
systemctl restart minetest@default
systemctl enable minetest@default
