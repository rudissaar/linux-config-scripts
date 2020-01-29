#!/usr/bin/env bash
# Script that installs sshesame, a fake SSH server that lets everyone in and logs their activity on current system.

LISTEN_ADDRESS='0.0.0.0'
LISTEN_PORT=2022
SERVER_VESION='SSH-2.0-OpenSSH_8.1'
JSON_LOGGING=0

SSHESAME_USER='sshesame'
SSHESAME_UID=972
SSHESAME_GID=972

GENERATE_AND_USE_PRIV_KEY=1
PRIV_KEY_BITS=3072
PRIV_KEY_TYPE='rsa'

PACKAGE_POOL='/usr/local'
ENABLE_SERVICES=0
RUN_FIREWALL_RULES=0

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

# Install required packages.
ENSURE_PACKAGE 'go' 'golang'
ENSURE_PACKAGE 'ssh-keygen' 'openssh'
ENSURE_PACKAGE 'firewall-cmd' 'firewalld'

# Temporary change GOPATH environment variable.
ORIGINAL_GOPATH=$(go env GOPATH)
export GOPATH="${PACKAGE_POOL}/share/go"
[[ -d "${GOPATH}" ]] || mkdir -p "${GOPATH}"

# Install sshesame from source.
go get -u github.com/jaksi/sshesame

# Create file and directory for configuration.
ETC_PATH='/etc/sshesame'
[[ -d "${ETC_PATH}" ]] || mkdir -p "${ETC_PATH}"

# Link sshesame binary.
[[ -d "${PACKAGE_POOL}/sbin" ]] || "${PACKAGE_POOL}/sbin"

# Create script that reads parameters from file.
cat > "${PACKAGE_POOL}/sbin/sshesame" <<EOL
#!/bin/sh

${GOPATH}/bin/sshesame \$(paste -d ' ' -s ${ETC_PATH}/sshesame.conf)

EOL

# Fix script permissions.
chmod +x "${PACKAGE_POOL}/sbin/sshesame"

# Create user for sshesame service.
if ! getent passwd "${SSHESAME_USER}" 1> /dev/null 2>&1; then
    groupadd \
        --gid ${SSHESAME_GID} \
        "${SSHESAME_USER}"

    useradd \
        --uid ${SSHESAME_UID} \
        --gid ${SSHESAME_GID} \
        --no-create-home \
        --home-dir "${ETC_PATH}" \
        --comment 'Fake SSH Server' \
        --shell '/sbin/nologin ' \
        "${SSHESAME_USER}"
fi

# Address and port.
cat > /etc/sshesame/sshesame.conf <<EOL
-listen_address ${LISTEN_ADDRESS}
-port ${LISTEN_PORT}
-server_version '${SERVER_VESION}'
EOL

# JSON logging.
[[ "${JSON_LOGGING}" == '1' ]] && echo '-json_logging' >> "${ETC_PATH}/sshesame.conf"

# Private key.
if [[ "${GENERATE_AND_USE_PRIV_KEY}" == 1 ]]; then
    [[ -f "${ETC_PATH}/host.key" ]] && rm "${ETC_PATH}/host.key"
    ssh-keygen -b ${PRIV_KEY_BITS} -t "${PRIV_KEY_TYPE}" -f "${ETC_PATH}/host.key" -q -N ''
    chown "${SSHESAME_USER}":${SSHESAME_USER} "${ETC_PATH}/host.key"
    [[ -f "${ETC_PATH}/host.key.pub" ]] && rm "${ETC_PATH}/host.key.pub"
    echo "-host_key ${ETC_PATH}/host.key" >> "${ETC_PATH}/sshesame.conf"
fi

# Create systemd service file for sshesame.
[[ -d /usr/local/lib/systemd/system ]] || mkdir -p /usr/local/lib/systemd/system

cat > /usr/local/lib/systemd/system/sshesame.service <<EOL
[Unit]
Description=A fake SSH server that lets everyone in and logs their activity
After=network.target remote-fs.target nss-lookup.target

[Service]
User=${SSHESAME_USER}
Group=${SSHESAME_USER}
Type=simple
ExecStart=/bin/sh ${PACKAGE_POOL}/sbin/sshesame
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true
Restart=always
StandardOutput=file:/var/log/sshesame.log

[Install]
WantedBy=multi-user.target
EOL

# Create file for logging.
touch /var/log/sshesame.log
chown root:"${SSHESAME_USER}" /var/log/sshesame.log
chmod 660 /var/log/sshesame.log
chmod +t /var/log/sshesame.log

# Create a file that can be used for uninstalling.
[[ -d "${PACKAGE_POOL}/share/sshesame" ]] || mkdir -p "${PACKAGE_POOL}/share/sshesame"

cat > "${PACKAGE_POOL}/share/sshesame/uninstall.txt" <<EOL
systemctl stop sshesame
systemctl disable sshesame
rm -f /usr/local/lib/systemd/system/sshesame.service
userdel sshesame
groupdel sshesame
rm -f /var/spool/mail/sshesame
rm -f "${PACKAGE_POOL}/sbin/sshesame"
rm -f "${GOPATH}/bin/sshesame"
rm -rf "${GOPATH}/src/github.com/jaksi/sshesame"
rmdir "${GOPATH}/src/github.com/jaksi" 2> /dev/null
rmdir "${GOPATH}/src/github.com" 2> /dev/null
rmdir "${GOPATH}/src" 2> /dev/null
rm -f "${ETC_PATH}/sshesame.conf"
rm -f "${ETC_PATH}/host.key"
rmdir "${ETC_PATH}" 2> /dev/null
rm -f /var/log/sshesame.log
rm -f ${PACKAGE_POOL}/sbin/sshesame
rm -f "${PACKAGE_POOL}/share/sshesame/uninstall.txt"
rmdir "${PACKAGE_POOL}/share/sshesame" 2> /dev/null
EOL

# Reload systemd daemon.
systemctl daemon-reload

# Restore GOPATH environment variable.
export GOPATH="${ORIGINAL_GOPATH}"

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" == '1' ]]; then
    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --add-port=${LISTEN_PORT}/tcp 1> /dev/null
    firewall-cmd --runtime-to-permanent 1> /dev/null
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo "firewall-cmd --add-port=${LISTEN_PORT}/tcp"
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Configuring service.
if [[ "${ENABLE_SERVICES}" == '1' ]]; then
    systemctl enable sshesame
    systemctl restart sshesame
else
    systemctl disable sshesame
    systemctl stop sshesame
fi

# Let user know that script has finished its job.
echo '> Finished.'

