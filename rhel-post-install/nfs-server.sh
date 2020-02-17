#!/usr/bin/env bash
# Script that install publically accessible NFS share on current system.

SHARE_DIR='/data'
SHARE_HOSTS='*'
SHARE_MODE='rw'

ENABLE_SERVICES=1
RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necessary.
ENSURE_PACKAGE () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGES="${*:2}"

    if [[ "${REQUIRED_BINARY}" != '-' ]]; then
        [[ -n "${REPO_PACKAGES}" ]] || REPO_PACKAGES="${REQUIRED_BINARY}"

        if command -v "${REQUIRED_BINARY}" 1> /dev/null; then
            REPO_PACKAGES=''
        fi
    fi

    [[ -n "${REPO_PACKAGES}" ]] || return

    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        echo '> Refreshing package repository.'
        yum check-update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        yum install -y "${REPO_PACKAGE}"
    done
}

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Check if SELinux is enabled on system.
SELINUX_ENABLED=0

if command -v selinuxenabled 1> /dev/null 2>&1; then
    if selinuxenabled; then
        SELINUX_ENABLED=1
    fi
fi

# Install packages and dependencies if necessary.
ENSURE_PACKAGE 'mount.nfs' 'nfs-utils'
ENSURE_PACKAGE 'fs4_getfacl' 'nfs4-acl-tools'

# Make sure that NFS share directory exists.
[[ -d "${SHARE_DIR}" ]] || mkdir -p "${SHARE_DIR}"

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
if [[ "${RUN_FIREWALL_RULES}" == '1' ]]; then
    # Make sure firewalld is installed.
    ENSURE_PACKAGE 'firewall-cmd' 'firewalld'

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

# Enable or disable RPC Bind service.
if [[ "${ENABLE_SERVICES}" == '1' ]]; then
    systemctl enable rpcbind
    systemctl restart rpcbind
else
    systemctl enable rpcbind
    systemctl stop rpcbind
fi

# Enable or disable NFS service.
if [[ "${ENABLE_SERVICES}" == '1' ]]; then
    systemctl enable nfs-server
    systemctl restart nfs-server
else
    systemctl disable nfs-server
    systemctl stop nfs-server
fi

# Let user know that script has finished its job.
echo '> Finished.'

