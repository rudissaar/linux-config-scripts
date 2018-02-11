#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != "0" ]]; then
    echo '> You need to become root before you can run this script.'
    exit 1
fi

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
