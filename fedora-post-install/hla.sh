#!/usr/bin/env bash
# Script that installs environment for High Level Assembly developemnt.

PACKAGE_POOL="/usr"
ORIGINAL_URL="http://www.plantation-productions.com/Webster/HighLevelAsm/HLAv2.16/linux.hla.tar.gz"
FALLBACK_URL="http://legacy.murda.eu/downloads/misc/hla-linux.tar.gz"

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
ENSURE_DEPENDENCY 'tar'
ENSURE_DEPENDENCY 'grep'
ENSURE_DEPENDENCY 'wget'

if [[ ${REPO_UPDATED} -eq 0 ]]; then
    dnf check-update 1> /dev/null
fi

# Install required packages.
dnf install -y \
    glibc.i686 \
    binutils

# Download HLA archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/hla-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/hla-${TMP_DATE}"

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
cp -r "${TMP_PATH}/usr/"* "${PACKAGE_POOL}/"

while IFS= read -r -d '' BINARY
do
    BASENAME=$(basename "${BINARY}")
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/${BASENAME}"
done < <(find "${PACKAGE_POOL}/hla" -maxdepth 1 -type f -executable -print0)

# Setup global environment variables.
if ! grep -Fq 'export hlalib=' /etc/profile; then
    echo "export hlalib=${PACKAGE_POOL}/hla/hlalib" >> /etc/profile
fi

if ! grep -Fq 'export hlainc=' /etc/profile; then
    echo "export hlainc=${PACKAGE_POOL}/hla/include" >> /etc/profile
fi

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

# Let user know that script has finished its job.
echo '> Finished.'

