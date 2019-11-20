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
    exit 1
fi

# Variable that keeps track if repository is already refreshed.
REPO_REFRESHED=0

# Function that checks if required binary exists and installs it if necessary.
ENSURE_DEPENDENCY () {
    REQUIRED_BINARY=$(basename "${1}")
    REPO_PACKAGE="${2}"

    which "${REQUIRED_BINARY}" 1> /dev/null 2>&1

    if [[ "${?}" != '0' ]]; then
        if [[ "${REPO_REFRESHED}" == '0' ]]; then
            dnf update --refresh
            REPO_REFRESHED=1
        fi

        dnf install -y "${REPO_PACKAGE}"
    fi
} 

# Download and install BleachBit package.
dnf install -y "${DOWNLOAD_URL}"

if [[ "${?}" != '0' ]]; then
    echo '> Unable to download required file, exiting.'
    exit 1
fi

# Check for requirements and install them if necessary.
ENSURE_DEPENDENCY 'pkexec' 'polkit'
ENSURE_DEPENDENCY 'python2' 'python2'
ENSURE_DEPENDENCY 'sed' 'sed'

if [[ "${REPO_REFRESHED}" == '0' ]]; then
    dnf update --refresh
    REPO_REFRESHED=1
fi

dnf install -y \
    python2-gobject \
    python2-scandir

# Block that applies no password policy for org.bleachbit directive.
if [[ "${POLKIT_NO_PASSWORD}" == '1' ]]; then
    ENSURE_DEPENDENCY 'xmllint' 'libxml2'
    NODES=('allow_any' 'allow_inactive' 'allow_active')
    
    for NODE in ${NODES[@]}
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

