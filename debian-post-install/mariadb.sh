#!/usr/bin/env bash

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
apt-get update -y
apt-get install -y mariadb-common mariadb-server mariadb-client

# Configure server.
mysql_secure_installation

# Making absolutely sure that service will be started on boot.
systemctl enable mariadb
systemctl start mariadb
