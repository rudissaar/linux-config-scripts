#!/usr/bin/env bash
# shellcheck disable=SC2016
# Script that install PCSX2 Playstation 2 emulator on Fedora GNU/Linux system.

USE_COPR_REPO=1
PACKAGE_POOL='/usr'
DOWNLOAD_URL='http://legacy.murda.eu/downloads/pcsx2/fedora/pcsx2-1.4-11.zip'

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Variable that holds Fedora version number.
FEDORA_VERSION=$(rpm -E %fedora)

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

# Install PCSX2 package from COPR repository.
if [[ "${USE_COPR_REPO}" == '1' ]]; then
    ENSURE_PACKAGE 'sed'
    ENSURE_PACKAGE 'wget'

    wget \
        "https://copr.fedorainfracloud.org/coprs/victoroliveira/pcsx2-git/repo/fedora-${FEDORA_VERSION}/victoroliveira-pcsx2-git-fedora-${FEDORA_VERSION}.repo" \
        -O '/etc/yum.repos.d/fedora-copr-pcsx2-git.repo'

    sed -i 's/$basearch/i386/' '/etc/yum.repos.d/fedora-copr-pcsx2-git.repo'

    ENSURE_PACKAGE 'pcsx2-git'

    # Let user know that script has finished its job.
    echo '> Finished.'
    exit 0
fi

# Install packages.
if [[ ${FEDORA_VERSION} -lt 30 ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    # Enable RPM Fusion repositories.
    dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm

    # Install PCSX2 package from repository.
    ENSURE_PACKAGE 'pcsx2'

    # Let user know that script has finished its job.
    echo '> Finished.'
    exit 0
fi

ENSURE_PACKAGE 'date' 'coreutils'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'unzip'
ENSURE_PACKAGE 'awk' 'gawk'
ENSURE_PACKAGE 'find' 'findutils'
ENSURE_PACKAGE '-' 'alsa-lib.i686'
ENSURE_PACKAGE '-' 'compat-wxGTK3-gtk2.i686'
ENSURE_PACKAGE '-' 'libaio.i686'
ENSURE_PACKAGE '-' 'joystick'
ENSURE_PACKAGE '-' 'mesa-libGLU.i686'
ENSURE_PACKAGE '-' 'portaudio.i686'
ENSURE_PACKAGE '-' 'soundtouch.i686'
ENSURE_PACKAGE '-' 'wxBase3.i686'

# Download PCSX2 archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/pcsx2-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/pcsx2-${TMP_DATE}"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required files.'
    echo '> Aborting.'
    exit 1
fi

# Extract PCSX2 archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
unzip -q "${TMP_FILE}" -d "${TMP_PATH}"

while IFS= read -r -d '' BINARY
do
    chmod +x "${BINARY}"
done < <(find "${TMP_PATH}/bin" -maxdepth 1 -type f -print0)

# Create file that can be used to remove PCSX2 files.
awk '{ printf "rm -r '${PACKAGE_POOL}'"; print }' "${TMP_PATH}/share/pcsx2/uninstall.txt" > "${TMP_PATH}/share/pcsx2/uninstall.tmp"
mv "${TMP_PATH}/share/pcsx2/uninstall.tmp" "${TMP_PATH}/share/pcsx2/uninstall.txt"

# Copy files.
cp -r "${TMP_PATH}/"* "${PACKAGE_POOL}/"

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

