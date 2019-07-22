#!/usr/bin/env bash

PAM_SU_FILE='/etc/pam.d/su'
REMOVE_INSTRUCTION_COMMENTS=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Check if 'sed' is installed on system, if it's not then install it.
which sed 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    dnf install -y sed
fi

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

# Let user know that script has finished it's job.
echo '> Finished.'

