#!/usr/bin/env bash

INSTALL_FOR_EVERYBODY=1

GET_STABLE_VERSION () {
    VERSION=$(curl -L -s https://teamspeak.com/en/downloads | grep -A 2 'Client 64-bit' | tail -n 1)
    echo $(echo ${VERSION})
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

    if [[ ! -f ${INSTALLER_PATH} ]]; then
        wget "${URL}${STABLE_VERSION}${INSTALLER}" -O ${INSTALLER_PATH}
    fi

    if [[ ! -f ${INSTALLER_PATH} ]]; then
        exit 1
    fi

    bash ${INSTALLER_PATH} --target ${DESTINATION}

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

if [[ ! -z ${INSTALL_FOR_EVERYBODY} ]]; then
    if [[ "${UID}" != '0' ]]; then
        echo '> You need root user permissions to install TeamSpeak 3 Client for everbody.'
        exit 1
    fi

    RUN_INSTALL_FOR_EVERYBODY
else
    RUN_INSTALL_FOR_USER
fi
