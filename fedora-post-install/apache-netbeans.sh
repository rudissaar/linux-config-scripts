#!/usr/bin/env bash
# Script that installs Apache NetBeans IDE on your system.

PACKAGE_POOL="/usr/local"
VERSION='11.2'
USE_ICON_FROM_ARCHIVE=0

if [[ "${VERSION}" == '11.0' ]]; then
    DOWNLOAD_EU_URL="https://www-eu.apache.org/dist/incubator/netbeans/incubating-netbeans/incubating-${VERSION}/incubating-netbeans-${VERSION}-bin.zip"
    DOWNLOAD_US_URL="https://www-us.apache.org/dist/incubator/netbeans/incubating-netbeans/incubating-${VERSION}/incubating-netbeans-${VERSION}-bin.zip"
else
    DOWNLOAD_EU_URL="https://www-eu.apache.org/dist/netbeans/netbeans/${VERSION}/netbeans-${VERSION}-bin.zip";
    DOWNLOAD_US_URL="https://www-us.apache.org/dist/netbeans/netbeans/${VERSION}/netbeans-${VERSION}-bin.zip";
fi

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necassary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"
    [[ -n "${REPO_PACKAGE}" ]] || REPO_PACKAGE="${REQUIRED_BINARY}"

    if ! command -v "${REQUIRED_BINARY}" 1> /dev/null; then
        if [[ "${REPO_UPDATED}" == '0' ]]; then
            dnf check-update 1> /dev/null
            REPO_UPDATED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
}

# Variable that keeps track if repository is already refreshed.
REPO_UPDATED=0

# Install dependencies if necassary.
ENSURE_DEPENDENCY 'wget'
ENSURE_DEPENDENCY 'grep'
ENSURE_DEPENDENCY 'unzip'
ENSURE_DEPENDENCY 'java' 'java-latest-openjdk'
ENSURE_DEPENDENCY 'javac' 'java-latest-openjdk-devel'

# Download Apache NetBeans archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/apache-netbeans-${TMP_DATE}.zip"
TMP_PATH="/tmp/apache-netbeans-${TMP_DATE}"

if ! wget "${DOWNLOAD_EU_URL}" -O "${TMP_FILE}"; then
    if ! wget "${DOWNLOAD_US_URL}" -O "${TMP_FILE}"; then
        echo '> Unable to download required files, exiting.'
        echo '> Aborting.'
        exit 1
    fi
fi

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
unzip -q "${TMP_FILE}" -d "${TMP_PATH}"

# Copy files.
cp -r "${TMP_PATH}/"* "${PACKAGE_POOL}/share/"

while IFS= read -r -d '' BINARY
do
    BASENAME=$(basename "${BINARY}")
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/${BASENAME}"
done < <(find "${PACKAGE_POOL}/share/netbeans/bin" -maxdepth 1 -type f -executable -print0)

# Create desktop entry for application.
if [[ ! -f "${PACKAGE_POOL}/share/applications/apache-netbeans.desktop" ]]; then
    if [[ "${USE_ICON_FROM_ARCHIVE}" != '0' ]]; then
        ICON="${PACKAGE_POOL}/share/netbeans/nb/netbans.png"
    else
        ICON='netbeans'
    fi

    cat > "${PACKAGE_POOL}/share/applications/apache-netbeans.desktop" <<EOL
[Desktop Entry]
Version=${VERSION}
Name=NetBeans
Comment=Integrated Development Environment
Exec=netbeans
Icon=${ICON}
Categories=Development;IDE;Java;
Terminal=false
Type=Application
Keywords=development;Java;IDE;platform;javafx;javase;
StartupWMClass=NetBeans IDE ${VERSION}
EOL
fi

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

