#!/usr/bin/env bash
# Script that installs TeamSpeak3 client on current system.

INSTALL_FOR_EVERYBODY=1

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

# Install dependencies if necessary.
ENSURE_PACKAGE 'curl'
ENSURE_PACKAGE 'grep'
ENSURE_PACKAGE 'wget'

# Function that fetches latest version number of TeamSpeak3 Client.
GET_STABLE_VERSION () {
    VERSION=$(curl -L -s 'https://teamspeak.com/en/downloads' | grep -A 2 'Client 64-bit' | tail -n 1)
    echo "${VERSION}"
}

RUN_INSTALL_FOR_EVERYBODY () {
    STABLE_VERSION=$(GET_STABLE_VERSION)
    URL='http://dl.4players.de/ts/releases/'
    DESTINATION='/opt/teamspeak3-client'

    if [[ "$(uname -m)" == 'x86_64' ]]; then
        INSTALLER="/TeamSpeak3-Client-linux_amd64-${STABLE_VERSION}.run"
        INSTALLER_PATH="/tmp${INSTALLER}"
    else
        INSTALLER="/TeamSpeak3-Client-linux_x86-${STABLE_VERSION}.run"
        INSTALLER_PATH="/tmp${INSTALLER}"
    fi

    if [[ ! -f "${INSTALLER_PATH}" ]]; then
        if ! wget "${URL}${STABLE_VERSION}${INSTALLER}" -O "${INSTALLER_PATH}"; then
            echo '> Unable to download required files, exiting.'
            echo '> Aborting.'
            exit 1
        fi
    fi

    bash "${INSTALLER_PATH}" --target "${DESTINATION}"

    if [[ ! -d '/usr/local/share/applications' ]]; then
        mkdir -p '/usr/local/share/applications'
    fi

    cat > '/usr/local/share/applications/teamspeak3-client.desktop' <<EOL
[Desktop Entry]
Version=${STABLE_VERSION}
Name=Teamspeak 3 Client
GenericName=Teamspeak
Exec=${DESTINATION}/ts3client_runscript.sh
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=${DESTINATION}/styles/default/logo-128x128.png
StartupWMClass=Teamspeak
StartupNotify=true
Categories=Network;InstantMessaging;
EOL
}

RUN_INSTALL_FOR_USER () {
    echo 'TODO'
}

if [[ -n "${INSTALL_FOR_EVERYBODY}" ]]; then
    if [[ "${UID}" != '0' ]]; then
        echo '> You need root user permissions to install TeamSpeak 3 Client for everbody.'
        echo '> Aborting.'
        exit 1
    fi

    RUN_INSTALL_FOR_EVERYBODY
else
    RUN_INSTALL_FOR_USER
fi

# Let user know that script has finished its job.
echo '> Finished.'

