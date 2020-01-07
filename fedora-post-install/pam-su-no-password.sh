#!/usr/bin/env bash
# Script that allows wheel group users to use su command without entering password.

PAM_SU_FILE='/etc/pam.d/su'
REMOVE_INSTRUCTION_COMMENTS=1

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

# Check if 'sed' is installed on system, if it's not then install it.
ENSURE_PACKAGE 'sed'

# Look for line with specific content and uncomment it if it's found.
sed -i \
    '/^#auth		required	pam_wheel.so use_uid$/s/^#//g' \
    "${PAM_SU_FILE}"

# Look for line with specific content and uncomment it if it's found.
sed -i \
    '/^#auth		sufficient	pam_wheel.so trust use_uid$/s/^#//g' \
    "${PAM_SU_FILE}"

# Block of code that removes instruction comments from file.
if [[ "${REMOVE_INSTRUCTION_COMMENTS}" == '1' ]]; then
    sed -i \
        '/^# Uncomment the following/d' \
        "${PAM_SU_FILE}"
fi

# Let user know that script has finished its job.
echo '> Finished.'

