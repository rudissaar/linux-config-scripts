#!/usr/bin/env bash
# Script that simplifies installing latest OnionShare from Github.
# Script also enables you to prevent nautilus package from installing.

# Option that helps you to prevent nautilus package from installing, it is useful if you are using some other
# desktop environment than Gnome.
WITHOUT_NAUTILUS=1

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install required packages.
dnf install -y \
    coreutils \
    curl \
    jq \
    rpm-build \
    sed \
    tar \
    wget

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

echo '> Finished.'
