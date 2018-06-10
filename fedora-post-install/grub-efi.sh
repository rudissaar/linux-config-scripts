#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

