#!/usr/bin/env bash
# Script that installs Wolfenstein: Enemy Territory 2.60b on Fedora GNU/Linux.

WET_DIR='/usr/local/games/enemy-territory'
DOWNLOAD_URL=''http://filebase.trackbase.net/et/full/et260b.x86_full.zip''

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

# Install requirements if necessary.
ENSURE_PACKAGE '-' 'glibc.i686' 'libglvnd-glx.i686' 'libstdc++.i686' 'libX11.i686' 'libXext.i686' 'pulseaudio-libs.i686'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'unzip'
ENSURE_PACKAGE 'modprobe' 'kmod'
ENSURE_PACKAGE 'linux32' 'util-linux'

# Download Wolfenstein: Enemy Territory archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/wet260b-${TMP_DATE}.zip"
TMP_PATH="/tmp/wet260b-${TMP_DATE}"

if ! wget "${DOWNLOAD_URL}" -O "${TMP_FILE}"; then
    echo '> Unable to download required file, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
unzip -q "${TMP_FILE}" -d "${TMP_PATH}"

INSTALLER="$(find "${TMP_PATH}" -maxdepth 1 -name '*.run' | head -n 1)"
chmod +x "${INSTALLER}"

# Run installer.
"${INSTALLER}" \
    --target "${TMP_PATH}" \
    --noexec \
    2> /dev/null

# Run setup script.
"${INSTALLER}/setup.sh" 2> /dev/null

# Copy files to destination folder.
[[ -d "${WET_DIR}" ]] || mkdir -p "${WET_DIR}"

cp "${TMP_PATH}/bin/Linux/x86/et.x86" "${WET_DIR}"
rm "${TMP_PATH}/etmain/description.txt"
cp -r "${TMP_PATH}/etmain" "${WET_DIR}"
rm "${TMP_PATH}/pb/PB_EULA.txt"
rm -r "${TMP_PATH}/pb/.directory"
rm -r "${TMP_PATH}/pb/htm"
cp -r "${TMP_PATH}/pb" "${WET_DIR}"
cp "${TMP_PATH}/ET.xpm" "${WET_DIR}/et.xpm"

# Enable required kernel modules.
modprobe snd-pcm-oss && modprobe snd-seq-device && modprobe snd-seq-oss

if [[ ! -f '/etc/modules-load.d/dsp.conf' ]]; then
    cat > '/etc/modules-load.d/dsp.conf' <<EOL
snd-pcm-oss
snd-seq-device
snd-seq-oss
EOL
fi

# Create desktop entry for application.
[[ ! -d /usr/local/share/applications ]] || mkdir -p /usr/local/share/applications

cat > "/usr/local/share/applications/wet.desktop" <<EOL
[Desktop Entry]
Version=2.60b
Name=Wolfenstein: Enemy Territory
Comment=World War II first-person shooter
Path=${WET_DIR}
Exec=linux32 ${WET_DIR}/et.x86
Icon=${WET_DIR}/et.xpm
Categories=Game;ActionGame;
Terminal=false
Type=Application
MimeType=x-scheme-handler/et;
Keywords=team-based;multiplayer;tactical;WWII;enemy;territory;
EOL

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

