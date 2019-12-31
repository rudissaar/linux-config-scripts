#!/usr/bin/env bash
# Script that installs latest version of BleachBit from offical homepage for Fedora GNU/Linux.

# Set this to 1 if you wish to remove all password requirements for org.bleachbit policy.
# By doing this your system will be less secure due to no required authentication.
POLKIT_NO_PASSWORD=0
POLKIT_FILE='/usr/share/polkit-1/actions/org.bleachbit.policy'

# URL from where package gets downloaded.
DOWNLOAD_URL='https://download.bleachbit.org/bleachbit-3.0-1.1.fc28.noarch.rpm'

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

# Download and install BleachBit package.
if ! dnf install -y "${DOWNLOAD_URL}"; then
    echo '> Unable to download required file, exiting.'
    echo '> Aborting.'
    exit 1
fi

# Check for requirements and install them if necessary.
ENSURE_PACKAGE 'pkexec' 'polkit'
ENSURE_PACKAGE 'python2'
ENSURE_PACKAGE '-' 'python2-gobject'
ENSURE_PACKAGE '-' 'python2-scandir'
ENSURE_PACKAGE 'sed'

# Block that applies no password policy for org.bleachbit directive.
if [[ "${POLKIT_NO_PASSWORD}" == '1' ]]; then
    ENSURE_DEPENDENCY 'xmllint' 'libxml2'
    NODES=('allow_any' 'allow_inactive' 'allow_active')
    
    for NODE in "${NODES[@]}"
    do
        xmllint --shell "${POLKIT_FILE}" 1> /dev/null <<EOF
cd /policyconfig/action[@id='org.bleachbit']/defaults/${NODE}
set yes
save
EOF
    done
fi

# Fix for desktop application file.
sed -i -E 's/^Exec=bleachbit-root$/Exec=pkexec bleachbit/g' /usr/share/applications/bleachbit-root.desktop

# Let user know that script has finished its job.
echo '> Finished.'

