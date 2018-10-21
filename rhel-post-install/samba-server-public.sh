#!/usr/bin/env bash

SHARE_DIR='/share/public'
SHARE_WRITABLE=1

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

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
which selinuxenabled 1> /dev/null 2>&1

if [[ "${?}" == '0' ]]; then
    selinuxenabled

    if [[ "${?}" == 0 ]]; then
        SELINUX_ENABLED=1
    fi
fi

# Install packages.
yum install -y samba

# Make sure share directory exists.
if [[ ! -d "${SHARE_DIR}" ]]; then
    mkdir -p "${SHARE_DIR}"
fi

# Set ownership and permissions for share directory.
chown -R nobody:nobody "${SHARE_DIR}"
chmod 775 "${SHARE_DIR}"
chmod g+s "${SHARE_DIR}"

# Apply SELinux rules if necessary.
if [[ "${SELINUX_ENABLED}" == '1' ]]; then
    setsebool -P samba_export_all_ro on
    setsebool -P samba_export_all_rw on

    # Install SELinux utils if necessary.
    which semanage 1> /dev/null 2>&1
    if [[ "${?}" != '0' ]]; then
        yum install -y policycoreutils-python-utils
    fi

    semanage fcontext -at public_content_rw_t "${SHARE_DIR}(/.*)?"
    restorecon "${SHARE_DIR}"
fi

# Add entry about share to /etc/samba/smb.conf file.
grep -Fq "[${SHARE_NAME}]" /etc/samba/smb.conf

if [[ "${?}" != '0' ]]; then
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
    yum install -y firewalld

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

