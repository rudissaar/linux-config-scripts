#!/usr/bin/env bash
# Script that install PCSX2 Playstation 2 emulator on Fedora GNU/Linux system.

PACKAGE_POOL='/usr'
DOWNLOAD_URL='http://legacy.murda.eu/downloads/pcsx2/fedora/pcsx2-1.4-11.zip'

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
FEDORA_VERSION=$(rpm -E %fedora)
if [[ ${FEDORA_VERSION} -lt 30 ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    # Enable RPM Fusion repositories.
    dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Install PCSX2 package from repository.
    dnf install -y pcsx2

    # Let user know that script has finished its job.
    echo '> Finished.'
    exit 0
fi

ENSURE_DEPENDENCY 'date' 'coreutils'
ENSURE_DEPENDENCY 'wget' 'wget'
ENSURE_DEPENDENCY 'unzip' 'unzip'

if [[ "${REPO_REFRESHED}" == '0' ]]; then
    dnf update --refresh
    REPO_REFRESHED=1
fi

dnf install -y \
    alsa-lib.i686 \
    compat-wxGTK3-gtk2.i686 \
    libaio.i686 \
    joystick \
    mesa-libGLU.i686 \
    portaudio.i686 \
    soundtouch.i686 \
    wxBase3.i686

# Download PCSX2 archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/pcsx2-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/pcsx2-${TMP_DATE}"

wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"

if [[ "${?}" != '0' ]]; then
    echo '> Unable to download required files, exiting.'
    exit 1
fi

# Extract PCSX2 archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
unzip -q "${TMP_FILE}" -d "${TMP_PATH}"

for BINARY in $(find "${TMP_PATH}/bin")
do
    chmod +x "${BINARY}"
done

# Copy files.
cp -r "${TMP_PATH}/"* "${PACKAGE_POOL}/"

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

