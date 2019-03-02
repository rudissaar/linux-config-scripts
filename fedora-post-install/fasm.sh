#!/usr/bin/env bash
# Script that installs the flat assembler (FASM) on Fedora GNU/Linux.

PACKAGE_POOL="/usr/local"

ORIGINAL_URL="https://flatassembler.net/fasm-1.73.09.tgz"
FALLBACK_URL="http://legacy.murda.eu/donwloads/misc/fasm-linux.tar.gz"

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
which grep 1> /dev/null 2>&1
[[ "${?}" == '0' ]] || dnf install -y grep

which wget 1> /dev/null 2>&1
[[ "${?}" == '0' ]] || dnf install -y wget

# Download FASM archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/fasm-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/fasm-${TMP_DATE}"

wget "${ORIGINAL_URL}" -O "${TMP_FILE}"

if [[ "${?}" != '0' ]]; then
    wget "${FALLBACK_URL}" -O "${TMP_FILE}"
fi

if [[ "${?}" != '0' ]]; then
    echo '> Unable to download required files, exiting.'
    exit 1
fi

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
tar -xf "${TMP_FILE}" --directory "${TMP_PATH}"

# Copy files.
cp -r "${TMP_PATH}/"* "${PACKAGE_POOL}/"

for BINARY in $(find "${PACKAGE_POOL}/fasm" -maxdepth 1 -type f -executable)
do
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/$(basename ${BINARY})"
done

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

echo '> Finished.'
