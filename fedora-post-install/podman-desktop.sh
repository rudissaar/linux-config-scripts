#!/usr/bin/env bash
# Script that installs the Podman Desktop application on your system.

PACKAGE_POOL='/usr/local'
PACKAGE_NAME='podman-desktop'

# If the user running this script is not root, then use the user's directory instead.
if [[ "${UID}" != '0' ]]; then 
    PACKAGE_POOL="${HOME}/.local"
fi

ENSURE_PACKAGE () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGES="${*:2}"

    if [[ "${UID}" != '0' ]]; then 
        if ! command -v "${REQUIRED_BINARY}" 1> /dev/null; then
            echo "> '${REQUIRED_BINARY}' is not installed on your system. exiting."
            exit 1
        fi
    fi

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

# Variable that keeps track of whether the repository is already refreshed.
REPO_REFRESHED=0

# Install required packages.
ENSURE_PACKAGE 'curl'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'jq'
ENSURE_PACKAGE 'sed'

# Fetch the version of the latest release and download the archive.
GITHUB_API_URL='https://api.github.com/repos/containers/podman-desktop/tags'
VERSION=$(curl -s "${GITHUB_API_URL}" | jq -r '.[0].name' | tr -d '"' | sed 's/^v//')
URL="https://github.com/containers/podman-desktop/releases/download/v${VERSION}/podman-desktop-${VERSION}.tar.gz"
ARCHIVE="/tmp/${PACKAGE_NAME}-${VERSION}.tar.gz"

# Download the archive.
if ! wget "${URL}" -O "${ARCHIVE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Extract the archive.
[[ -d "${PACKAGE_POOL}/share/${PACKAGE_NAME}" ]] || mkdir -p "${PACKAGE_POOL}/share/${PACKAGE_NAME}"
tar -xzmf "${ARCHIVE}" -C "${PACKAGE_POOL}/share/${PACKAGE_NAME}" --strip-components=1 && rm "${ARCHIVE}"

# Create desktop entry for application.
[[ -d "${PACKAGE_POOL}/share/applications" ]] || mkdir -p "${PACKAGE_POOL}/share/applications"

cat > "${PACKAGE_POOL}/share/applications/${PACKAGE_NAME}.desktop" <<EOL
[Desktop Entry]
Name=Podman Desktop
Version=${VERSION}
Comment=A graphical tool for developing on containers and Kubernetes.
Exec=${PACKAGE_POOL}/share/${PACKAGE_NAME}/podman-desktop
Type=Application
Icon=podman-desktop
Categories=Development;Utility;
Keywords=Containers;Podman;Virtualization;
EOL

# Create a file that can be used for uninstalling.
cat > "${PACKAGE_POOL}/share/${PACKAGE_NAME}/uninstall.txt" <<EOL
rm -rf '${PACKAGE_POOL}/share/${PACKAGE_NAME}/'
rm -f '${PACKAGE_POOL}/share/applications/${PACKAGE_NAME}.desktop'
EOL

# Let user know that script has finished its job.
echo '> Execution of the script has finished.'
