#!/usr/bin/env bash
# Script that installs packages for Qt5 development.

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
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

# Install packages.
ENSURE_PACKAGE '-' 'qt5-devel' 'qt5-qtbase-devel'
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'sed'

# Link qmake binary.
if ! command -v qmake 1> /dev/null 2>&1; then
    if command -v qmake-qt5 1> /dev/null 2>&1; then
        ln -sf "$(command -v qmake-qt5)" /usr/local/bin/qmake
    fi
fi

# Enable debug messages.
[[ -d /usr/share/qt5 ]] || mkdir -p /usr/share/qt5

if ! grep -Fq '*.debug=' /usr/share/qt5/qtlogging.ini; then
    echo '*.debug=true' >> /usr/share/qt5/qtlogging.ini
else
    sed -i -E 's/^\*\.debug=.*/*.debug=true/g' /usr/share/qt5/qtlogging.ini
fi

# Let user know that script has finished its job.
echo '> Finished.'

