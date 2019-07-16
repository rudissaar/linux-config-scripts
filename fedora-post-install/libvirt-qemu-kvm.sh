#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf install -y \
    qemu-kvm \
    libvirt \
    libvirt-client \
    virt-install \
    virt-manager

# Enable libvirt service.
systemctl enable libvirtd
systemctl restart libvirtd

# Print info about KVM capabilities.
virt-host-validate

# Let user know that script has finished it's job.
echo '> Finished.'

