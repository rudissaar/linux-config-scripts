#!/usr/bin/env bash
# Script that install publicly accessible NFS share on current system.

SHARE_DIR='/data'
SHARE_HOSTS='*'
SHARE_MODE='rw'

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
        dnf check-update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        dnf install -y "${REPO_PACKAGE}"
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
if [[ "${RUN_FIREWALL_RULES}" == '1' ]]; then
    # Make sure firewalld is installed.
    ENSURE_PACKAGE 'firewall-cmd' 'firewall-cmd'

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

# Let user know that script has finished its job.
echo '> Finished.'

