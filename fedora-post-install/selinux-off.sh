#!/usr/bin/env bash
# Script that disables SELinux on current system.

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Check if SELinux is enabled.
selinuxenabled

# Perform actions.
if [[ "${?}" == '0' ]]; then
    # Disable SELinux in runtime.
    echo -n 0 > /sys/fs/selinux/enforce

    # Make sure that sed binary is installed, we'll need this on next step.
    which sed 1> /dev/null 2>&1
    [[ "${?}" == '0' ]] || dnf install -y sed

    # Disable SELinux from config.
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

# Remove packages.
dnf remove -y selinux* setroubleshoot-server

# Let user know that script has finished it's job.
echo '> Finished.'

