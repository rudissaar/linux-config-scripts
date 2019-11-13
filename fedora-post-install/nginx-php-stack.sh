#!/usr/bin/env bash
# Script that installs nginx and php stack on current system.

ENABLE_SERVICES=1

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Install requirements.

# sed.
which sed 1> /dev/null 2>&1

# Install packages if necessary.
if [[ "${?}" != '0' ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    dnf install -y sed
fi

# nginx.
which nginx 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    dnf install -y nginx
fi

# php.
which php 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    dnf install -y \
        php-cli \
        php-gd \
        php-intl \
        php-json \
        php-jsonlint \
        php-mbstring \
        php-mysqlnd \
        php-opcache \
        php-pdo \
        php-process \
        php-xml
fi

# php-fpm.
which php-fpm 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    dnf install -y php-fpm
fi

# composer.
which composer 1> /dev/null 2>&1

if [[ "${?}" != '0' ]]; then
    if [[ "${REPO_REFRESHED}" == '0' ]]; then
        dnf update --refresh
        REPO_REFRESHED=1
    fi

    dnf install -y composer
fi

# Fix configuration.
sed -i 's/^user = .*$/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/^group = .*$/group = nginx/g' /etc/php-fpm.d/www.conf

# Fix ownerships.
chown -R nginx:nginx \
    /var/lib/php/opcache \
    /var/lib/php/session \
    /var/lib/php/wsdlcache

chown root \
    /var/lib/php/opcache \
    /var/lib/php/session \
    /var/lib/php/wsdlcache

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

