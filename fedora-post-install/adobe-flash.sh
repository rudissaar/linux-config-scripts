#!/usr/bin/env bash
# Script that installs Adobe Flash player on your system.

MIME_TYPE_FILE_POOL='/usr/share/mime'
MIME_TYPE_FILE="${MIME_TYPE_FILE}/packages/freedesktop.org.xml"

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

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Add and enable repositories.
rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux

# Install packages and required dependencies.
ENSURE_PACKAGE 'sed'
ENSURE_PACKAGE 'update-mime-database' 'shared-mime-info'
ENSURE_PACKAGE 'flash-player-properties' 'flash-plugin'
ENSURE_PACKAGE '-' 'alsa-plugins-pulseaudio'
ENSURE_PACKAGE '-' 'libcurl'

# Fix the issue where browser tries to download .swf file instead of playing.
if [[ -f "${MIME_TYPE_FILE}" ]]; then
    sed -i \
        's/vnd.adobe.flash.movie/x-shockwave-flash/g' \
        "${MIME_TYPE_FILE}"
fi

# Update MIME database.
update-mime-database "${MIME_TYPE_FILE_POOL}"

# Let user know that script has finished its job.
echo '> Finished.'

