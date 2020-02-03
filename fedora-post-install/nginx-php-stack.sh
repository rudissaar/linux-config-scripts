#!/usr/bin/env bash
# Script that installs nginx and php stack on current system.

ENABLE_SERVICES=1
SET_CGI_FIX_PATHINFO_TO_0=1
EXPOSE_PHP_OFF=1

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

# Install packages and dependencies if necessary.
ENSURE_PACKAGE 'sed'
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'nginx'
ENSURE_PACKAGE 'php-fpm'
ENSURE_PACKAGE 'composer'
ENSURE_PACKAGE '-' \
    'php-cli' 'php-gd' 'php-intl' 'php-json' 'php-jsonlint' 'php-mbstring' 'php-mysqlnd' \
    'php-opcache' 'php-pdo' 'php-pecl-apcu' 'php-pecl-apcu-bc' 'php-pecl-imagick' 'php-pecl-memcache' \
    'php-pgsql' 'php-process' 'php-xml'

# Fix configuration.
sed -i 's/^user = .*$/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/^group = .*$/group = nginx/g' /etc/php-fpm.d/www.conf

if [[ "${SET_CGI_FIX_PATHINFO_TO_0}" == '1' ]]; then
    if ! grep -Fq 'cgi.fix_pathinfo=' /etc/php.ini; then
        echo 'cgi.fix_pathinfo=0' >> /etc/php.ini
    else
        sed -i -E 's/^;?cgi.fix_pathinfo=.*$/cgi.fix_pathinfo=0/g' /etc/php.ini
    fi
fi

if [[ "${EXPOSE_PHP_OFF}" == '1' ]]; then
    if ! grep -Fq 'expose_php =' /etc/php.ini; then
        echo 'expose_php = Off' >> /etc/php.ini
    else
        sed -i -E 's/^;?expose_php\s?=\s?.*$/expose_php = Off/g' /etc/php.ini
    fi
fi

# Fix ownerships.
chown -R nginx:nginx \
    /var/lib/php/opcache \
    /var/lib/php/session \
    /var/lib/php/wsdlcache

chown root \
    /var/lib/php/opcache \
    /var/lib/php/session \
    /var/lib/php/wsdlcache

usermod -G apache nginx
usermod -G nginx apache

# Configuring services.
if [[ "${ENABLE_SERVICES}" == '1' ]]; then
    systemctl enable nginx
    systemctl start nginx

    systemctl enable php-fpm
    systemctl start php-fpm
else
    systemctl disable nginx
    systemctl stop nginx

    systemctl disable php-fpm
    systemctl stop php-fpm
fi

# Let user know that script has finished its job.
echo '> Finished.'

