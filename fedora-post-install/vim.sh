#!/usr/bin/env bash
# Script that installs and configures vim editor on current system.

OVERWRITE_USERS_VIMRC=1

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
            dnf check-update 1> /dev/null
            REPO_UPDATED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Variable that keeps track if repository is already refreshed.
REPO_UPDATED=0

# Install dependencies if necassary.
ENSURE_DEPENDENCY 'grep'
ENSURE_DEPENDENCY 'awk' 'gawk'

# Install packages if necessary.
if ! command -v vim 1> /dev/null; then
    if [[ ${REPO_UPDATED} -eq 0 ]]; then
        dnf check-update 1> /dev/null
    fi

    dnf install -y vim
fi

# Replace vi command with vim.
if ! grep -Fq 'alias vi=' /etc/bashrc; then
    echo >> /etc/bashrc
    echo "alias vi='vim'" >> /etc/bashrc
fi

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
if [[ "${OVERWRITE_USERS_VIMRC}" = '1' ]]; then
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

