#!/usr/bin/env bash
# Script that disables history for bash shell on current system.

CLEAR_HISTORY_FOR_ROOT=1
CLEAR_HISTORY_FOR_USERS=0

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
        apt-get update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        apt-get install -y "${REPO_PACKAGE}"
    done
}

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Install packages if necessary.
ENSURE_PACKAGE 'sed'
ENSURE_PACKAGE 'grep'

if ! grep -Fxq 'HISTFILE=/dev/null' /etc/profile; then
   if  grep -Fxq 'HISTSIZE' /etc/profile; then
        sed -i "/HISTSIZE/a export HISTFILE=/dev/null\\n" /etc/profile
    else
        echo -e "\\nexport HISTFILE=/dev/null" >> /etc/profile
    fi
fi

# Remove .bash_history file for root.
if [[ "${CLEAR_HISTORY_FOR_ROOT}" == '1' ]]; then
    rm /root/.bash_history 2> /dev/null
fi

# Remove .bash_history file for normal users.
if [[ "${CLEAR_HISTORY_FOR_USERS}" == '1' ]]; then
    if [[ -f /etc/login.defs ]]; then
        ENSURE_DEPENDENCY 'awk' 'gawk'

        UID_MIN="$(grep '^UID_MIN' /etc/login.defs)"
        UID_MAX="$(grep '^UID_MAX' /etc/login.defs)"
        USERNAMES="$(awk -F':' -v "min=${UID_MIN##UID_MIN}" -v "max=${UID_MAX##UID_MAX}" '{ if ( $3 >= min && $3 <= max ) print $1}' /etc/passwd)"

        for USERNAME in ${USERNAMES}; do
            HOME_DIR=$(eval echo "~${USERNAME}")
            rm "${HOME_DIR}/.bash_history" 2> /dev/null
        done
    else
        echo '> Unable to remove .bash_history file for normal users, missing file: "/etc/login.defs".'
    fi
fi

# Let user know that script has finished its job.
echo '> Finished.'

