#!/usr/bin/env bash
# Script that install publicly accessible Samba share on current system.

SHARE_DIR='/share/public'
SHARE_WRITABLE=1

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necassary.
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

# Get name of the share from directory path.
SHARE_NAME=$(basename "${SHARE_DIR}")

# Translate ${SHARE_WRITABLE} value to keywords.
if [[ "${SHARE_WRITABLE}" == '1' ]] || [[ "${SHARE_WRITABLE}" == 'Yes' ]]; then
    SHARE_WRITABLE='Yes'
else
    SHARE_WRITABLE='No'
fi

# Check if SELinux is enabled on system.
SELINUX_ENABLED=0

if command -v selinuxenabled 1> /dev/null 2>&1; then
    if selinuxenabled 1> /dev/null; then
        SELINUX_ENABLED=1
    fi
fi

# Install packages.
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE '-' 'samba'

# Make sure that share directory exists.
[[ -d "${SHARE_DIR}" ]] || mkdir -p "${SHARE_DIR}"

# Set ownership and permissions for share directory.
chown -R nobody:nobody "${SHARE_DIR}"
chmod 775 "${SHARE_DIR}"
chmod g+s "${SHARE_DIR}"

# Apply SELinux rules if necessary.
if [[ "${SELINUX_ENABLED}" == '1' ]]; then
    setsebool -P samba_export_all_ro on
    setsebool -P samba_export_all_rw on

    # Install SELinux utils if necessary.
    ENSURE_PACKAGE 'semanage' 'policycoreutils-python-utils'

    semanage fcontext -at public_content_rw_t "${SHARE_DIR}(/.*)?"
    restorecon "${SHARE_DIR}"
fi

# Add entry about share to /etc/samba/smb.conf file.
if ! grep -Fq "[${SHARE_NAME}]" /etc/samba/smb.conf; then
    cat >> '/etc/samba/smb.conf' <<EOL

[${SHARE_NAME}]
    comment = Public Samba Share
    path = ${SHARE_DIR}
    writable = ${SHARE_WRITABLE}
    public = Yes
EOL
fi

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" = '1' ]]; then
    # Make sure firewalld is installed.
    ENSURE_PACKAGE 'firewalld'

    # Enable Firewalld service.
    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --add-service=samba
    firewall-cmd --runtime-to-permanent
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo 'firewall-cmd --add-service=samba'
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Enable Samba service.
systemctl enable smb
systemctl restart smb

# Let user know that script has finished its job.
echo '> Finished.'

