#!/usr/bin/env bash

OVERWRITE_USERS_VIMRC=1

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages if necessary.
which vim 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    dnf update --refresh
    dnf install -y vim
fi

# Replace vi command with vim.
grep -Fq 'alias vi=' /etc/bashrc

if [[ "${?}" != '0' ]]; then
    echo >> /etc/bashrc
    echo "alias vi='vim'" >> /etc/bashrc
fi

# Create .vimrc file in /etc/skel directory.
if [[ ! -f /etc/skel/.vimrc ]]; then
    touch /etc/skel/.vimrc
fi

# Enable syntax.
grep -Fq 'syntax on' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'syntax on' >> /etc/skel/.vimrc
fi

# Display line numbers.
grep -Fq 'set number' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set number' >> /etc/skel/.vimrc
fi

# Disable visual mode.
grep -Fq 'set mouse-=a' /etc/skel/.vimrc

if [[ "${?}" != '0' ]]; then
    echo 'set mouse-=a' >> /etc/skel/.vimrc
fi

# Set size of tab.
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
            chown ${USERNAME}:${USERNAME} "${HOME_DIR}/.vimrc"
        done
    else
        echo '> Unable to overwrite .vimrc for normal users, missing file: "/etc/login.defs".'
    fi
fi

# Let user know that script has finished it's job.
echo '> Finished.'

