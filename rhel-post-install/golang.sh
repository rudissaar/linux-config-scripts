#!/usr/bin/env bash
# Script that installs Go programming language on your system.

PACKAGE_POOL='/usr/local'
VERSION='1.13'
DOWNLOAD_URL="https://dl.google.com/go/go${VERSION}.linux-amd64.tar.gz"

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
        yum check-update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        yum install -y "${REPO_PACKAGE}"
    done
}

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Install packages and dependencies if necessary.
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'tar'
ENSURE_PACKAGE 'find' 'findutils'

# Download golang archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/golang-${TMP_DATE}.tar.gz"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Extract archive.
[[ -d "${PACKAGE_POOL}/share" ]] || mkdir -p "${PACKAGE_POOL}/share"
tar -C "${PACKAGE_POOL}/share" -xzf "${TMP_FILE}"

# Link binaries.
while IFS= read -r -d '' BINARY
do
    BASENAME=$(basename "${BINARY}")
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/${BASENAME}"
done < <(find "${PACKAGE_POOL}/share/go/bin" -maxdepth 1 -type f -executable -print0)

# Cleanup.
rm -rf "${TMP_FILE}"

# Let user know that script has finished its job.
echo '> Finished.'

