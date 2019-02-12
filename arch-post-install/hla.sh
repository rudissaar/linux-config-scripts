#!/usr/bin/env bash

PACKAGE_POOL="/usr"

ORIGINAL_URL="http://www.plantation-productions.com/Webster/HighLevelAsm/HLAv2.16/linux.hla.tar.gz"

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
which grep 1> /dev/null 2>&1
[[ "${?}" == '0' ]] || pacman --noconfirm -S grep

which wget 1> /dev/null 2>&1
[[ "${?}" == '0' ]] || pacman --noconfirm -S wget

# Download HLA archive.
TMP_DATE="$(date +%s)"
TMP_FILE="/tmp/hla-${TMP_DATE}.tar.gz"
TMP_PATH="/tmp/hla-${TMP_DATE}"

wget "${ORIGINAL_URL}" -O "${TMP_FILE}"

# Extract archive.
[[ -d "${TMP_PATH}" ]] || mkdir -p "${TMP_PATH}"
tar -xf "${TMP_FILE}" --directory "${TMP_PATH}"

# Copy files.
cp -r "${TMP_PATH}/usr/"* "${PACKAGE_POOL}/"

for BINARY in $(find "${PACKAGE_POOL}/hla" -maxdepth 1 -type f -executable)
do
    ln -sf "${BINARY}" "${PACKAGE_POOL}/bin/$(basename ${BINARY})"
done

# Setup global environment variables.
grep -Fq 'export hlalib=' /etc/profile
if [[ "${?}" != '0' ]]; then
    echo "export hlalib=${PACKAGE_POOL}/hla/hlalib" >> /etc/profile
fi

grep -Fq 'export hlainc=' /etc/profile
if [[ "${?}" != '0' ]]; then
    echo "export hlainc=${PACKAGE_POOL}/hla/include" >> /etc/profile
fi

# Cleanup.
rm -rf "${TMP_FILE}" "${TMP_PATH}"

echo '> Finished.'

