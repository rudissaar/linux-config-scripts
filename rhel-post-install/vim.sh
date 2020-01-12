#!/usr/bin/env bash
# Script that installs and configures vim editor on current system.

OVERWRITE_USERS_VIMRC=1

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

# Install packages and dependencies if necessary.
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'awk' 'gawk'
ENSURE_PACKAGE 'vim'

# Replace vi command with vim.
if ! grep -Fq 'alias vi=' /etc/bashrc; then
    echo >> /etc/bashrc
    echo "alias vi='vim'" >> /etc/bashrc
fi

# Create /etc/skel directory if it doesn't exist.
[[ -d '/etc/skel' ]] || mkdir -p '/etc/skel'

# Create .vimrc file in /etc/skel directory.
if [[ ! -f /etc/skel/.vimrc ]]; then
    touch /etc/skel/.vimrc
fi

# Create .gvimrc file in /etc/skel directory.
if [[ ! -f /etc/skel/.gvimrc ]]; then
    touch /etc/skel/.gvimrc
fi

# Enable syntax.
if ! grep -Fq 'syntax on' /etc/skel/.vimrc; then
    echo 'syntax on' >> /etc/skel/.vimrc
fi

# Display line numbers.
if ! grep -Fq 'set number' /etc/skel/.vimrc; then
    echo 'set number' >> /etc/skel/.vimrc
fi

# Disable visual mode.
if ! grep -Fq 'set mouse-=a' /etc/skel/.vimrc; then
    echo 'set mouse-=a' >> /etc/skel/.vimrc
fi

# Enable visual mode for gvim.
if ! grep -Fq 'set mouse=a' /etc/skel/.gvimrc; then
    echo 'set mouse=a' >> /etc/skel/.gvimrc
fi

# Set size of tab.
if ! grep -Fq 'set tabstop=4' /etc/skel/.vimrc; then
    echo 'set tabstop=4' >> /etc/skel/.vimrc
fi

# Use spaces instead of tabs.
if ! grep -Fq 'set expandtab' /etc/skel/.vimrc; then
    echo 'set expandtab' >> /etc/skel/.vimrc
fi

# Set size of indent.
if ! grep -Fq 'set shiftwidth=4' /etc/skel/.vimrc; then
    echo 'set shiftwidth=4' >> /etc/skel/.vimrc
fi

# Block that populates user directories with generated .vimrc file.
if [[ "${OVERWRITE_USERS_VIMRC}" == '1' ]]; then
    cp /etc/skel/.vimrc "${HOME}/.vimrc"

    if [[ -f /etc/login.defs ]]; then
        UID_MIN="$(grep '^UID_MIN' /etc/login.defs)"
        UID_MAX="$(grep '^UID_MAX' /etc/login.defs)"
        USERNAMES="$(awk -F':' -v "min=${UID_MIN##UID_MIN}" -v "max=${UID_MAX##UID_MAX}" '{ if ( $3 >= min && $3 <= max ) print $1}' /etc/passwd)"

        for USERNAME in ${USERNAMES}; do
            HOME_DIR=$(eval echo "~${USERNAME}")
	        cp /etc/skel/.vimrc "${HOME_DIR}/.vimrc"
	        cp /etc/skel/.gvimrc "${HOME_DIR}/.gvimrc"
            chown "${USERNAME}:${USERNAME}" "${HOME_DIR}/.vimrc" "${HOME_DIR}/.gvimrc"
        done
    else
        echo '> Unable to overwrite .vimrc for normal users, missing file: "/etc/login.defs".'
    fi
fi

# Let user know that script has finished its job.
echo '> Finished.'

