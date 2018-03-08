#!/usr/bin/env bash

OVERWRITE_USERS_VIMRC=1

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
apt-get update -y
apt-get install -y \
    vim

# Replace vi command with vim.
grep -Fq 'alias vi=' /etc/bash.bashrc

if [[ "${?}" != '0' ]]; then
    echo >> /etc/bash.bashrc
    echo "alias vi='vim'" >> /etc/bash.bashrc
    exec bash
fi

if [[ ! -f /etc/skel/.vimrc ]]; then
    touch /etc/skel/.vimrc
fi

# Enable syntax.
grep -Fq 'syntax on' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'syntax on' >> /etc/skel/.vimrc
fi

# Disable visual mode.
grep -Fq 'set mouse-=a' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set mouse-=a' >> /etc/skel/.vimrc
fi

# Sset size of tab.
grep -Fq 'set tabstop=4' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set tabstop=4' >> /etc/skel/.vimrc
fi

# Use spaces instead of tabs.
grep -Fq 'set expandtab' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set expandtab' >> /etc/skel/.vimrc
fi

# Set size of indent.
grep -Fq 'set shiftwidth=4' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set shiftwidth=4' >> /etc/skel/.vimrc
fi

if [[ "${OVERWRITE_USERS_VIMRC}" = '1' ]]; then
    cp /etc/skel/.vimrc "${HOME}/.vimrc"

    if [[ -f /etc/login.defs ]]; then
        UID_MIN="$(grep '^UID_MIN' /etc/login.defs)"
        UID_MAX="$(grep '^UID_MAX' /etc/login.defs)"
        DIRS="$(awk -F':' -v "min=${UID_MIN##UID_MIN}" -v "max=${UID_MAX##UID_MAX}" '{ if ( $3 >= min && $3 <= max ) print $6}' /etc/passwd)"

        for DIR in ${DIRS}; do
	    cp /etc/skel/.vimrc "${DIR}/.vimrc"
        done
    else
        echo '> Unable to overwrite .vimrc for normal users, missing file: "/etc/login.defs".'
    fi
fi

echo '> Finished.'

