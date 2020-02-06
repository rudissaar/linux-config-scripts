#!/usr/bin/env bash
# Script that installs Streama media server on your system.

PACKAGE_POOL="/usr/local"
VERSION='1.7.3'

DOWNLOAD_URL="https://github.com/streamaserver/streama/releases/download/v${VERSION}/streama-${VERSION}.jar"

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
ENSURE_PACKAGE '-' 'groovy-lib'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'java' 'java-latest-openjdk'

# Download Streama archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/streama-${TMP_DATE}.jar"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Copy files.
[[ -d "${PACKAGE_POOL}/share/streama" ]] || mkdir -p "${PACKAGE_POOL}/share/streama"
mv "${TMP_FILE}" "${PACKAGE_POOL}/share/streama/streama.jar"

# Create executable script.
[[ -d "${PACKAGE_POOL}/sbin" ]] || mkdir -p "${PACKAGE_POOL}/sbin"

cat > "${PACKAGE_POOL}/sbin/streama" <<EOL
#!/bin/sh

java -jar "${PACKAGE_POOL}/share/streama/streama.jar"

EOL

# Fix script permissions.
chmod +x "${PACKAGE_POOL}/sbin/streama"

# Create a file that can be used for uninstalling.
cat > "${PACKAGE_POOL}/share/streama/uninstall.txt" <<EOL
rm -f "${PACKAGE_POOL}/sbin/streama"
rm -f "${PACKAGE_POOL}/share/streama/streama.jar"
rm -f "${PACKAGE_POOL}/share/streama/uninstall.txt"
rmdir "${PACKAGE_POOL}/share/streama" 2> /dev/null
EOL

# Let user know that script has finished its job.
echo '> Finished.'

