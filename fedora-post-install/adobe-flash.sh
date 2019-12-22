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

# Variable that keeps track if repository is already refreshed.
REPO_UPDATED=0

# Function that checks if required binary exists and installs it if necassary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"
    [[ -n "${REPO_PACKAGE}" ]] || REPO_PACKAGE="${REQUIRED_BINARY}"

    if ! command -v "${REQUIRED_BINARY}" 1> /dev/null; then
        if [[ "${REPO_UPDATED}" == '0' ]]; then
            dnf check-update 1> /dev/null
            REPO_UPDATED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Add and enable repositories.
rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux

# Install packages and required dependencies.
ENSURE_DEPENDENCY 'sed'
ENSURE_DEPENDENCY 'update-mime-database' 'shared-mime-info'

if [[ "${REPO_UPDATED}" == '0' ]]; then
    dnf check-update 1> /dev/null
    REPO_UPDATED=1
fi

dnf install -y \
    flash-plugin \
    alsa-plugins-pulseaudio \
    libcurl

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

