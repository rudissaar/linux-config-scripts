#!/usr/bin/env bash
# Script that simplifies installing latest OnionShare from Github.
# Script also enables you to prevent nautilus package from installing.

# Option that helps you to prevent nautilus package from installing, it is useful if you are using some other
# desktop environment than GNOME.
WITHOUT_NAUTILUS=1

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
ENSURE_PACKAGE '-' 'coreutils'
ENSURE_PACKAGE 'curl'
ENSURE_PACKAGE 'jq'
ENSURE_PACKAGE 'rpmbuild' 'rpm-build'
ENSURE_PACKAGE 'sed'
ENSURE_PACKAGE 'tar'
ENSURE_PACKAGE 'wget'

# Fetch URL of the latest release by using Github API.
URL="$(curl -s "https://api.github.com/repos/micahflee/onionshare/tags" | jq .[0].tarball_url | tr -d '"')"

# Generate unique filename for tar archive.
TMP_DATE="$(date +%s)"
TARBALL="/tmp/onionshare-${TMP_DATE}.tar.gz"

# Download tar file by using wget..
wget "${URL}" -O "${TARBALL}"

if [[ -f "${TARBALL}" ]]; then
    [[ -d "/tmp/onionshare-${TMP_DATE}" ]] || mkdir "/tmp/onionshare-${TMP_DATE}"
    tar -xf "${TARBALL}" -C "/tmp/onionshare-${TMP_DATE}"

    # Capture name of the directory that contains extracted files.
    PACKAGE_ROOT=$(ls -d "/tmp/onionshare-${TMP_DATE}/micahflee-onionshare-"*)
else
    echo '> Unable to locate tar archive, exiting.'
fi

if [[ -f "${PACKAGE_ROOT}/install/build_rpm.sh" ]]; then
    # Alter contents of the shell script to prevent nautilus package from installing.
    if [[ "${WITHOUT_NAUTILUS}" != '0' ]]; then
        sed -e s/nautilus-python,//g -i "${PACKAGE_ROOT}/install/build_rpm.sh"
    fi

    # Execute script that generates RPM package.
    bash "${PACKAGE_ROOT}/install/build_rpm.sh"
fi

# Capture name of the generated RPM package.
RPM_PACKAGE=$(ls "${PACKAGE_ROOT}/dist/onionshare-"*'noarch.rpm')

if [[ -f "${RPM_PACKAGE}" ]]; then
    # Install RPM package that we just generated.
    dnf install -y "${RPM_PACKAGE}"
else
    echo '> Failed to generate RPM package, exiting.'
fi

# Cleanup
rm -rf "${TARBALL}" "/tmp/onionshare-${TMP_DATE}"

# Let user know that script has finished its job.
echo '> Finished.'

