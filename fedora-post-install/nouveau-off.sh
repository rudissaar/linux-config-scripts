#!/usr/bin/env bash
# Script that disables nouveau module in kernel.

# You need root permissions to run this script.
if [[ "${UID}" != "0" ]]; then
    echo '> You need to become root before you can run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necessary.
ENSURE_PACKAGE () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGES="${*:2}"

    if [[ "${REQUIRED_BINARY}" != '-' ]]; then
        [[ -n "${REPO_PACKAGES}" ]] || REPO_PACKAGES="${REQUIRED_BINARY}"

        if command -v "${REQUIRED_BINARY}" 1> /dev/null; then
            REPO_PACKAGES=''
        fi
    fi

    [[ -n "${REPO_PACKAGES}" ]] || return

    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        echo '> Refreshing package repository.'
        dnf check-update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        dnf install -y "${REPO_PACKAGE}"
    done
}

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Install dependencies.
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'sed'

# Remove Xorg package for Nouveau.
dnf remove -y xorg-x11-drv-nouveau*
dnf autoremove -y

# Blacklist Nouveau even after its uninstalled to prevent kernel module's ones.
if [[ ! -f '/etc/modprobe.d/blacklist-nouveau.conf' ]]; then
    cat > '/etc/modprobe.d/blacklist-nouveau.conf' <<EOL
blacklist nouveau
blacklist lbm-nouveau
options nouveau off
alias nouveau off
alias lbm-nouveau off
EOL
fi

# Change GRUB params to disable Nouveau.
grep -Fxq 'rd.driver.blacklist=nouveau' /etc/default/grub

if [[ "${?}" == '1' ]]; then
    sed -i '/GRUB_CMDLINE_LINUX/a GRUB_CMDLINE_LINUX_DEFAULT="rd.driver.blacklist=nouveau"' /etc/default/grub
fi

# Update GRUB. 
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

# Let user know that script has finished its job.
echo '> Finished.'

