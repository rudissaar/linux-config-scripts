#!/usr/bin/env bash
# Script that installs OBS studio linux browser plugin for the current system.
# https://github.com/bazukas/obs-linuxbrowser

DOWNLOAD_URL='https://github.com/bazukas/obs-linuxbrowser/releases/download/0.6.1/linuxbrowser0.6.1-obs23.0.2-64bit.tgz'
PLUGINS_DIR="/usr/share/obs/obs-plugins"

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

# Install dependencies if necessary.
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'tar'
ENSURE_PACKAGE 'find' 'findutils'
ENSURE_PACKAGE 'GConf2'

# Download OBS linux browser plugin archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/obs-linux-browser-plugin-${TMP_DATE}.tgz"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Extract archive.
[[ -d "${PLUGINS_DIR}" ]] || mkdir -p "${PLUGINS_DIR}"
tar --no-same-owner -xzf "${TMP_FILE}" -C "${PLUGINS_DIR}"

# Fix permissions.
find "${PLUGINS_DIR}/obs-linuxbrowser" -type d -print0 | xargs -0 chmod 0755
find "${PLUGINS_DIR}/obs-linuxbrowser" -type f -print0 | xargs -0 chmod 0644

# Link library.
ln -sf "${PLUGINS_DIR}/obs-linuxbrowser/bin/64bit/libobs-linuxbrowser.so" /usr/lib64/obs-plugins/obs-linuxbrowser.so

# Cleanup.
rm -rf "${TMP_FILE}"

# Let user know that script has finished its job.
echo '> Finished.'

