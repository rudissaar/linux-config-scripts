#!/usr/bin/env bash
# 

DOWNLOAD_URL='http://legacy.murda.eu/downloads/pcsx2/fedora/pcsx2-1.4-11.tar.gz'

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Function that checks if required binary exists and installs it if necessary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"

    which "${REQUIRED_BINARY}" 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        if [[ "${REPO_REFRESHED}" == '0' ]]; then
            dnf update --refresh
            REPO_REFRESHED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Install packages.
ENSURE_DEPENDENCY 'date' 'coreutils'
ENSURE_DEPENDENCY 'wget' 'wget'
ENSURE_DEPENDENCY 'tar' 'tar'

# Download PCSX2 archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/pcsx2-$(date +%s).tar.gz"

wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"

if [[ "${?}" != '0' ]]; then
    echo '> Unable to download required files, exiting.'
    exit 1
fi

# Extract PCSX2 archive.
tar -xf "${TMP_FILE}" --directory /

# Cleanup.
rm -rf "${TMP_FILE}"

# Let user know that script has finished its job.
echo '> Finished.'

