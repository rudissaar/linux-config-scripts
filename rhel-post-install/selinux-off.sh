#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Check if SELinux is enabled.
selinuxenabled

# If it's already disabled then just exit.
if [[ "${?}" != '0' ]]; then
    exit
fi

# Disable SELinux in runtime.
echo -n 0 > /sys/fs/selinux/enforce

# Disable SELinux from config.
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# Remove packages.
yum remove -y selinux*

