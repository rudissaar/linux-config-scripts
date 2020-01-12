#!/usr/bin/env bash
# Script that installs sshesame, a fake SSH server that lets everyone in and logs their activity on current system.

PACKAGE_POOL='/usr/local'
ENABLE_SERVICES=1

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

# Temporary change GOPATH environment variable.
ORIGINAL_GOPATH=$(go env GOPATH)
export GOPATH="${PACKAGE_POOL}/share/go"
[[ -d "${GOPATH}" ]] || mkdir -p "${GOPATH}"

# Install sshesame from source.
go get -u github.com/jaksi/sshesame

# Link sshesame binary.
[[ -d "${PACKAGE_POOL}/sbin" ]] || "${PACKAGE_POOL}/sbin"
ln -sf "${GOPATH}/bin/sshesame" "${PACKAGE_POOL}/sbin/sshesame"

# Create file and directory for configuration.
[[ -d /etc/sshesame ]] || mkdir -p /etc/sshesame
[[ -f /etc/sshesame/sshesame.conf ]] && mv /etc/sshesame/sshesame.conf /etc/sshesame/sshesame.conf.bak

cat > '/etc/sshesame/sshesame.conf' <<EOL
-listen_address 0.0.0.0
EOL

# Create systemd service file for sshesame.
[[ -d /usr/local/lib/systemd/system ]] || mkdir -p /usr/local/lib/systemd/system

if [[ ! -f /usr/local/lib/systemd/system/sshesame.service ]]; then
    cat > /usr/local/lib/systemd/system/sshesame.service <<EOL
[Unit]
Description=A fake SSH server that lets everyone in and logs their activity.
After=network.target remote-fs.target nss-lookup.target

[Service]
User=nobody
Group=nobody
Type=simple
ExecStart=${PACKAGE_POOL}/sbin/sshesame $(paste -d ' ' -s /etc/sshesame.conf)
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd daemon.
systemctl daemon-reload
fi

# Restore GOPATH environment variable.
export GOPATH="${ORIGINAL_GOPATH}"

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

