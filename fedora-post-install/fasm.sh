#!/usr/bin/env bash
# Script that installs the flat assembler (FASM) on Fedora GNU/Linux.

PACKAGE_POOL="/usr/local"

ORIGINAL_URL="https://flatassembler.net/fasm-1.73.13.tgz"
FALLBACK_URL="http://legacy.murda.eu/downloads/misc/fasm-linux.tar.gz"

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

# Install packages.
ENSURE_PACKAGE 'tar'
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'find' 'findutils'

# Download FASM archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/fasm-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/fasm-${TMP_DATE}"

if ! wget "${ORIGINAL_URL}" -O "${TMP_FILE}"; then
    if ! wget "${FALLBACK_URL}" -O "${TMP_FILE}"; then
        echo '> Unable to download required files, exiting.'
        echo '> Aborting.'
        exit 1
    fi
fi

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
tar -xf "${TMP_FILE}" --directory "${TMP_PATH}"

# Copy files.
[[ -d "${PACKAGE_POOL}/share/fasm" ]] || mkdir -p "${PACKAGE_POOL}/share/fasm"
cp -r "${TMP_PATH}/fasm/"* "${PACKAGE_POOL}/share/fasm"

while IFS= read -r -d '' BINARY
do
    BASENAME=$(basename "${BINARY}")
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/${BASENAME}"
done < <(find "${PACKAGE_POOL}/share/fasm" -maxdepth 1 -type f -executable -print0)

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

