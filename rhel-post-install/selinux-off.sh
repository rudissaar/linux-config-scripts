#!/usr/bin/env bash
# Script that disables SELinux on current system.

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necassary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGES="${*:2}"
    [[ -n "${REPO_PACKAGES}" ]] || REPO_PACKAGES="${REQUIRED_BINARY}"

    if ! command -v "${REQUIRED_BINARY}" 1> /dev/null; then
        if [[ "${REPO_UPDATED}" == '0' ]]; then
            yum check-update 1> /dev/null
            REPO_UPDATED=1
        fi

        for REPO_PACKAGE in ${REPO_PACKAGES}
        do
            yum install -y "${REPO_PACKAGE}"
        done
    fi
}

# Variable that keeps track if repository is already refreshed.
REPO_UPDATED=0

if selinuxenabled; then
    # Install packages if necassary.
    ENSURE_DEPENDENCY 'sed'

    # Disable SELinux in runtime.
    echo -n 0 > /sys/fs/selinux/enforce

    # Disable SELinux from config.
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

# Remove packages.
yum remove -y selinux*

# Let user know that script has finished its job.
echo '> Finished.'

