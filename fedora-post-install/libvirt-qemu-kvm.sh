#!/usr/bin/env bash
# Script that installs libvirt QEMU/KVM stack on current system.

# Set this to 1 if you wish to remove all password requirements for org.libvirt.unix policy.
# By doing this your system will be less secure due to no required authentication.
POLKIT_NO_PASSWORD=0
POLKIT_FILE='/usr/share/polkit-1/actions/org.libvirt.unix.policy'

# Just an extra measure to make sure that IPv4 forwarding gets enabled on host system.
ENABLE_IPV4_FORWARDING=0

# If set to 1, libvirtd service will be enabled and started on system.
ENABLE_SERVICES=1

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Function that checks if required binary exists and installs it if necessary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"

    which "${REQUIRED_BINARY}" 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        if [[ "${REPO_REFRESHED}" == '0' ]]; then
            dnf update --refresh
            REPO_REFRESHED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Install packages.
dnf update --refresh
REPO_REFRESHED=1

dnf install -y \
    qemu-kvm \
    libvirt \
    libvirt-client \
    virt-install \
    virt-manager

# Configuring service.
if [[ "${ENABLE_SERVICES}" == '1' ]]; then
    systemctl enable libvirtd
    systemctl restart libvirtd
else
    systemctl disable libvirtd
    systemctl stop libvirtd
fi

# Block that applies no password policy for org.libvirt.unix directive.
if [[ "${POLKIT_NO_PASSWORD}" == '1' ]]; then
    ENSURE_DEPENDENCY 'xmllint' 'libxml2'
    NODES=('allow_any' 'allow_inactive' 'allow_active')
    
    for NODE in ${NODES[@]}
    do
        xmllint --shell "${POLKIT_FILE}" 1> /dev/null <<EOF
cd /policyconfig/action[@id='org.libvirt.unix.manage']/defaults/${NODE}
set yes
save
EOF
    done
fi

# IP forwarding.
if [[ "${ENABLE_IPV4_FORWARDING}" == '1' ]]; then
    echo -n 1 > /proc/sys/net/ipv4/ip_forward

    ENSURE_DEPENDENCY 'sed' 'sed'
    ENSURE_DEPENDENCY 'grep' 'grep'

    sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf
    grep -Fq 'net.ipv4.ip_forward=1' /etc/sysctl.conf

    if [[ "${?}" != '0' ]]; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
fi

# Print info about KVM capabilities.
virt-host-validate

# Let user know that script has finished its job.
echo '> Finished.'

