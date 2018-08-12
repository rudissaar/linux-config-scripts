#!/usr/bin/env bash

SHARE_DIR='/data'
SHARE_HOSTS='*'
SHARE_MODE='rw'

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Check if SeLinux is enabled on system.
SELINUX_ENABLED=0
which selinuxenabled 1> /dev/null 2>&1

if [[ "${?}" == '0' ]]; then
    selinuxenabled

    if [[ "${?}" == 0 ]]; then
        SELINUX_ENABLED=1
    fi
fi

# Install packages.
dnf install -y \
    nfs-utils \
    nfs4-acl-tools

# Make sure NFS share directory exists.
if [[ ! -d "${SHARE_DIR}" ]]; then
    mkdir -p "${SHARE_DIR}"
fi

# Apply SeLinux rules if necessary.
if [[ "${SELINUX_ENABLED}" == '1' ]]; then
    setsebool -P nfs_export_all_ro on
    setsebool -P nfs_export_all_rw on
fi

# Add entry about share to /etc/exports file.
cat >> '/etc/exports' <<EOL
${SHARE_DIR} ${SHARE_HOSTS}(${SHARE_MODE})
EOL

# Export entries.
exportfs -avr

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" = '1' ]]; then
    # Make sure firewalld is installed.
    dnf install -y firewalld

    # Enable Firewalld service.
    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --add-service=rpc-bind
    firewall-cmd --add-service=mountd
    firewall-cmd --add-service=nfs
    firewall-cmd --runtime-to-permanent
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo 'firewall-cmd --add-service=rpc-bind'
    echo 'firewall-cmd --add-service=mountd'
    echo 'firewall-cmd --add-service=nfs'
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Enable RPC Bind service.
systemctl enable rpcbind
systemctl restart rpcbind

# Enable NFS service.
systemctl enable nfs-server
systemctl restart nfs-server

