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

# Function that checks if required binary exists and installs it if necassary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"
    [[ -n "${REPO_PACKAGE}" ]] || REPO_PACKAGE="${REQUIRED_BINARY}"

    if ! command -v "${REQUIRED_BINARY}" 1> /dev/null; then
        if [[ "${REPO_UPDATED}" == '0' ]]; then
            dnf check-update
            REPO_UPDATED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Variable that keeps track if repository is already refreshed.
REPO_UPDATED=0

# Check if 'sed' is installed on system, if it's not then install it.
ENSURE_DEPENDENCY 'sed'

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

