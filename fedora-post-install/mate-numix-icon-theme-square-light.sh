#!/usr/bin/env bash

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

THEME_NAME='Mate-Numix-Square-Light'
THEME_DISPLAY_NAME='Mate Numix Square Light'

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

# Install required packages.
ENSURE_PACKAGE '-' 'numix-icon-theme-square'
ENSURE_PACKAGE 'sed'

# Create a copy of base icon theme for new one.
ICONS_PATH="/usr/share/icons/${THEME_NAME}"
[[ -d "${ICONS_PATH}" ]] && rm -rf "${ICONS_PATH}"
cp -r '/usr/share/icons/Numix-Square' "${ICONS_PATH}"

# Modify theme's name in index file.
sed -i "s/Name=.*/Name=${THEME_DISPLAY_NAME}/" "${ICONS_PATH}/index.theme"

# Copy over icons for panels.
cp -ruL /usr/share/icons/Numix-Light/* "${ICONS_PATH}/" 2> /dev/null
rm "${ICONS_PATH}/icon-theme.cache" "${ICONS_PATH}/16/panel" "${ICONS_PATH}/22/panel" "${ICONS_PATH}/24/panel"
ln -sf '/usr/share/icons/Numix-Light/16/panel' "${ICONS_PATH}/16/panel"
ln -sf '/usr/share/icons/Numix-Light/22/panel' "${ICONS_PATH}/22/panel"
ln -sf '/usr/share/icons/Numix-Light/24/panel' "${ICONS_PATH}/24/panel"


# Let user know that script has finished its job.
echo '> Finished.'

