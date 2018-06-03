#!/usr/bin/env bash

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg

