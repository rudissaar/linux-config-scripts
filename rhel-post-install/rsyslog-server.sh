#!/usr/bin/env bash
# Scripts that installs rsyslog daemon on fresh installation of RHEL.

RUN_FIREWALL_RULES=0

# You need root permissions to run this script.
if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
yum install -y rsyslog sed

# Edit configuration file.
sed -i '/#$ModLoad imudp/s/^#//g' /etc/rsyslog.conf
sed -i '/#$UDPServerRun 514/s/^#//g' /etc/rsyslog.conf

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" = '1' ]]; then
    # Make sure firewalld is installed.
    yum install -y firewalld

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

