#!/usr/bin/env bash
# Script that regenerates grub efi config file.

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

# Let user know that script has finished its job.
echo '> Finished.'

