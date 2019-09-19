#!/usr/bin/env bash
# Script that installs Adobe Flash player on your system.

MIME_TYPE_FILE_POOL='/usr/share/mime'
MIME_TYPE_FILE="${MIME_TYPE_FILE}/packages/freedesktop.org.xml"

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Add and enable repositories.
rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux

# Install packages and required dependencies.
dnf install -y \
    flash-plugin \
    alsa-plugins-pulseaudio \
    libcurl \
    sed \
    shared-mime-info

# Fix the issue where browser tries to download .swf file instead of playing.
if [[ -f "${MIME_TYPE_FILE}" ]]; then
    sed -i \
        's/vnd.adobe.flash.movie/x-shockwave-flash/g' \
        "${MIME_TYPE_FILE}"
fi

# Update MIME database.
update-mime-database "${MIME_TYPE_FILE_POOL}"

# Let user know that script has finished it's job.
echo '> Finished.'

