#!/usr/bin/env bash
# Script that replaces LightDM display manager with GDM one.

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf update --refresh
dnf install -y gdm

# Disable LightDM.
systemctl disable lightdm

# Enable GDM.
systemctl enable gdm

# Block that perform replacing display manager.
if [[ "${?}" != '0' ]]; then
    echo '> Replacing LightDM with GDM failed.'
    echo '> Re-enabling LightDM and removing GDM package.'
    
    systemctl disable gdm
    systemctl enable lightdm
    dnf remove -y gdm
fi

# Let user know that script has finished its job.
echo '> Finished.'

