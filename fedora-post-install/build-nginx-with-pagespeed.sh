#!/usr/bin/env bash
# Script that builds specific version of nginx with pagespeed module on current system.

NGINX_VERSION='1.17.7'
NGINX_DOWNLOAD_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

NGINX_PAGESPEED_URL='https://github.com/apache/incubator-pagespeed-ngx/archive/v1.13.35.2-stable.tar.gz'
PSOL_URL='https://dl.google.com/dl/page-speed/psol/1.13.35.2-x64.tar.gz'

PACKAGE_POOL='/usr/local'

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that performs cleanup.
CLEANUP () {
    rm -rf \
        "${TMP_NGINX_FILE}" \
        "${TMP_NGINX_PATH}" \
        "${TMP_PAGESPEED_FILE}" \
        "${TMP_PAGESPEED_PATH}" \
        1> /dev/null 2>&1
}

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
ENSURE_PACKAGE '-' 'zlib-devel' 'libuuid-devel' 'openssl-devel'
ENSURE_PACKAGE 'wget'
ENSURE_PACKAGE 'tar'
ENSURE_PACKAGE 'unzip'
ENSURE_PACKAGE 'make'
ENSURE_PACKAGE 'g++' 'gcc-c++'
ENSURE_PACKAGE 'pcre-config' 'pcre-devel'

# Download nginx source archive.
TMP_DATE="$(date +%s)"
TMP_NGINX_FILE="/tmp/nginx-${TMP_DATE}.tar.gz"
TMP_NGINX_PATH="/tmp/nginx-${TMP_DATE}"

if ! wget "${NGINX_DOWNLOAD_URL}" -O "${TMP_NGINX_FILE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    CLEANUP
    exit 1
fi

# Download pagespeed source archive.
TMP_PAGESPEED_FILE="/tmp/pagespeed-${TMP_DATE}.tar.gz"
TMP_PAGESPEED_PATH="/tmp/pagespeed-${TMP_DATE}"

if ! wget "${NGINX_PAGESPEED_URL}" -O "${TMP_PAGESPEED_FILE}"; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    CLEANUP
    exit 1
fi

# Extract archives.
[[ -d "${TMP_NGINX_PATH}" ]] || mkdir -p "${TMP_NGINX_PATH}"
tar -xzf "${TMP_NGINX_FILE}" -C "${TMP_NGINX_PATH}"
mv "${TMP_NGINX_PATH}/nginx"*/* "${TMP_NGINX_PATH}"

[[ -d "${TMP_PAGESPEED_PATH}" ]] || mkdir -p "${TMP_PAGESPEED_PATH}"
tar -xzf "${TMP_PAGESPEED_FILE}" -C "${TMP_PAGESPEED_PATH}"
mv "${TMP_PAGESPEED_PATH}/"*pagespeed*/* "${TMP_PAGESPEED_PATH}"

# Download required library for pagespeed module.
cd "${TMP_PAGESPEED_PATH}"

if ! wget "${PSOL_URL}" -O './psol.tar.gz'; then
    echo '> Unable to download required files, exiting.'
    echo '> Aborting.'
    CLEANUP
    exit 1
fi

# Extract PSOL archive.
tar -xzf 'psol.tar.gz'

cd - 1> /dev/null 2>&1

# Configure nginx build.
cd "${TMP_NGINX_PATH}"

./configure \
    --prefix=${PACKAGE_POOL}/share/nginx-local \
    --sbin-path=${PACKAGE_POOL}/sbin/nginx-local \
    --conf-path=${PACKAGE_POOL}/etc/nginx-local/nginx-local.conf \
    --pid-path=/run/nginx-local.pid \
    --lock-path=/run/nginx-local.lock \
    --error-log-path=/var/log/nginx-local/error.log \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_auth_request_module \
    --with-http_sub_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-mail=dynamic \
    --add-module=${TMP_PAGESPEED_PATH}

# Build.
make && make modules && make install clean

cd - 1> /dev/null 2>&1

# Cleanup.
CLEANUP

# Let user know that script has finished its job.
echo '> Finished.'

