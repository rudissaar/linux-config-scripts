#!/usr/bin/env bash

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

# Install dependencies if necessary.
ENSURE_PACKAGE 'dircolors' 'coreutils'
ENSURE_PACKAGE 'grep'

# Configuration.
if ! grep -Fq "export LS_OPTIONS='--color=auto'" /etc/bash.bashrc; then
    echo "export LS_OPTIONS='--color=auto'" >> /etc/bash.bashrc
fi

if ! grep -Fq "eval \$(dircolors)" /etc/bash.bashrc; then
    echo "eval \$(dircolors)" >> /etc/bash.bashrc
fi

if ! grep -Fq "alias ls='ls \${LS_OPTIONS}'" /etc/bash.bashrc; then
    echo "alias ls='ls \${LS_OPTIONS}'" >> /etc/bash.bashrc
fi

if ! grep -Fq "alias grep='grep --color=auto'" /etc/bash.bashrc; then
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc
fi


# Let user know that script has finished its job.
echo '> Finished.'

