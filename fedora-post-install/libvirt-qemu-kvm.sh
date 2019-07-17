#!/usr/bin/env bash

# Set this to 1 if you wish to remove all password requirements for org.libvirt.unix policy.
# By doing this your system will be less secure due no authentication is required.
POLKIT_NO_PASSWORD=0
POLKIT_FILE='/usr/share/polkit-1/actions/org.libvirt.unix.policy'

# Just an extra measure to make sure that IPv4 forwarding gets enabled on host system.
ENABLE_IPV4_FORWARDING=0

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

# Block that applies no password policy for org.libvirt.unix directive.
if [[ "${POLKIT_NO_PASSWORD}" == '1' ]]; then
    which sed 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        dnf install -y sed
    fi

    sed -i 's/auth_admin_keep/yes/g' "${POLKIT_FILE}"
fi

# IP forwarding.
if [[ "${ENABLE_IPV4_FORWARDING}" == '1' ]]; then
    echo -n 1 > /proc/sys/net/ipv4/ip_forward

    which sed 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        dnf install -y sed
    fi

    sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

    which grep 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        dnf install -y grep
    fi

    grep -Fq 'net.ipv4.ip_forward=1' /etc/sysctl.conf

    if [[ "${?}" != '0' ]]; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
fi

# Print info about KVM capabilities.
virt-host-validate

# Let user know that script has finished it's job.
echo '> Finished.'

