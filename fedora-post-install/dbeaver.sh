#!/usr/bin/env bash
# Script that installs DBeaver Community Edition on Fedora GNU/Linux.

URL="https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm"

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf install -y "${URL}"

# Let user know that script has finished it's job.
echo '> Finished.'

