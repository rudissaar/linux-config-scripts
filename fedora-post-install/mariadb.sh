#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Upgrade packages.
dnf update -y

# Install mariadb.
dnf install -y mariadb mariadb-server

# Enable it.
systemctl enable mariadb
systemctl start mariadb

# Configure service.
mysql_secure_installation

