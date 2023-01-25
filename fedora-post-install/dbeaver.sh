#!/usr/bin/env bash
# Script that installs DBeaver Community Edition on Fedora GNU/Linux.

RENAME_DESKTOP_ENTRY=1

URL="https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm"

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

# Install packages.
dnf install -y "${URL}"

# Rename desktop entry.
if [[ "${RENAME_DESKTOP_ENTRY}" == 1 ]]; then
    ENSURE_PACKAGE 'sed'
    sed -i 's/^Name=.*$/Name=DBeaver/g' /usr/share/applications/dbeaver-ce.desktop
fi

# Let user know that script has finished its job.
echo '> Finished.'
