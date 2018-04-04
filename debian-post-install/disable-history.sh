#!/usr/bin/env bash

CLEAR_HISTORY_FOR_ROOT=1
CLEAR_HISTORY_USERS=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

grep -Fxq 'HISTFILE=/dev/null' /etc/profile

if [[ "${?}" = '1' ]]; then
    grep -Fxq 'HISTSIZE' /etc/profile

    if [[ "${?}" = '0' ]]; then
        sed -i "/HISTSIZE/a export HISTFILE=/dev/null\n" /etc/profile
    else
        echo -e "\nexport HISTFILE=/dev/null" >> /etc/profile
    fi
fi

# Remove .bash_history file for root.
if [[ "${CLEAR_HISTORY_FOR_ROOT}" = '1' ]]; then
    rm /root/.bash_history 2> /dev/null
fi

# Remove .bash_history file for normal users.
if [[ "${CLEAR_HISTORY_FOR_USERS}" = '1' ]]; then
    if [[ -f /etc/login.defs ]]; then
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

echo '> Finished.'

