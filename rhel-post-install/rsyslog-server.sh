#!/usr/bin/env bash
# shellcheck disable=SC2016
# Scripts that installs rsyslog daemon on fresh installation of RHEL.

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Function that checks if required binary exists and installs it if necassary.
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
        yum check-update 1> /dev/null
        REPO_REFRESHED=1
    fi

    for REPO_PACKAGE in ${REPO_PACKAGES}
    do
        yum install -y "${REPO_PACKAGE}"
    done
}

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Install dependencies and packages if necessary.
ENSURE_PACKAGE 'sed'
ENSURE_PACKAGE 'rsyslogd' 'rsyslog'

# Edit configuration file.
sed -i '/#$ModLoad imudp/s/^#//g' /etc/rsyslog.conf
sed -i '/#$UDPServerRun 514/s/^#//g' /etc/rsyslog.conf

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" == '1' ]]; then
    # Make sure firewalld is installed.
    ENSURE_PACKAGE 'firewall-cmd' 'firewalld'

    # Enable Firewalld service.
    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --add-service=syslog
    firewall-cmd --runtime-to-permanent
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo 'firewall-cmd --add-service=syslog'
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Enable rsyslog service.
systemctl enable rsyslog
systemctl restart rsyslog

# Let user know that script has finished its job.
echo '> Finished.'

