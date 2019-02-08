#!/usr/bin/env bash
# Script that installs MATE Desktop environment on fresh Arch linux installation.

USERNAME='user'
OVERWRITE_USERS_XINITRC=1

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
pacman --noconfirm -S \
    xorg-server \
    xorg-xinit \
    lightdm \
    lightdm-gtk-greeter \
    mate \
    mate-terminal \
    ttf-dejavu \
    networkmanager \
    network-manager-applet \
    pulseaudio \
    pulseaudio-alsa

# Add normal user with default parameters.
useradd -m ${USERNAME}
passwd ${USERNAME}

# Create default .xinitrc file.
echo 'exec mate-session' > /etc/skel/.xinitrc

# Copy .xinitrc file to every normal user's home directory.
if [[ "${OVERWRITE_USERS_XINITRC}" = '1' ]]; then
    if [[ -f /etc/login.defs ]]; then
        UID_MIN="$(grep '^UID_MIN' /etc/login.defs)"
        UID_MAX="$(grep '^UID_MAX' /etc/login.defs)"
        USERNAMES="$(awk -F':' -v "min=${UID_MIN##UID_MIN}" -v "max=${UID_MAX##UID_MAX}" '{ if ( $3 >= min && $3 <= max ) print $1}' /etc/passwd)"

        for USERNAME in ${USERNAMES}; do
            HOME_DIR=$(eval echo "~${USERNAME}")
            cp /etc/skel/.xinitrc "${HOME_DIR}/.xinitrc"
            chown ${USERNAME}:${USERNAME} "${HOME_DIR}/.xinitrc"
        done
    else
        echo '> Unable to overwrite .xinitrc for normal users, missing file: "/etc/login.defs".'
    fi
fi

# Enable lightdm service.
systemctl enable lightdm
systemctl start lightdm

echo '> Finished.'

