#!/usr/bin/env bash
# Script that installs latest version of DuckStation for Fedora GNU/Linux.

PACKAGE_POOL="/usr/local"

# URL from where package gets downloaded.
DOWNLOAD_URL='https://github.com/stenzek/duckstation/releases/download/latest/DuckStation-x64.AppImage'

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

# Install required packages.
ENSURE_PACKAGE 'wget'

# Download DuckStation binary.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/duckstation-${TMP_DATE}.AppImage"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required files.'
    echo '> Aborting.'
    exit 1
fi

# Create a directory for binary.
PACKAGE_PATH="${PACKAGE_POOL}/share/duckstation"
[[ -d "${PACKAGE_PATH}" ]] || mkdir -p "${PACKAGE_PATH}"

# Copy AppImage to dedicated path and set up the rest.
APP_IMAGE="${PACKAGE_PATH}/duckstation.AppImage"
cp "${TMP_FILE}" "${APP_IMAGE}"
chmod +x "${APP_IMAGE}"
ln -sf "${APP_IMAGE}" "${PACKAGE_POOL}/bin/duckstation"

# Cleanup.
rm -rf "${TMP_FILE}"

# Let user know that script has finished its job.
echo '> Finished.'

