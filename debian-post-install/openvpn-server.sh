#!/usr/bin/env bash

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
apt-get update -y
apt-get install -y openvpn easy-rsa openssl ufw

# Remove useless folders if they exist and are empty.
rmdir /etc/openvpn/server 1> /dev/null 2>&1
rmdir /etc/openvpn/client 1> /dev/null 2>&1

# Move example configuration file to OpenVPN's directory.
cp \
    /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz \
    /etc/openvpn/server.conf.gz

gunzip /etc/openvpn/server.conf.gz

# Uncomment redirect-gateway line.
sed -i '/;push "redirect-gateway def1 bypass-dhcp"/s/^;//g' /etc/openvpn/server.conf

# Uncomment and set DNS servers.
sed -i 's/^;push "dhcp-option DNS .*/push "dhcp-option DNS 8.8.8.8"/' /etc/openvpn/server.conf
sed -i -r '0,/dhcp-option DNS 8.8.8.8/s/8.8.8.8/8.8.4.4/' /etc/openvpn/server.conf

# Uncomment user and group lines.
sed -i '/;user nobody/s/^;//g' /etc/openvpn/server.conf
sed -i '/;group nogroup/s/^;//g' /etc/openvpn/server.conf

# Enable IPv4 forward if not enabled.
echo -n 1 > /proc/sys/net/ipv4/ip_forward

# If sysctl.conf file contains line for forwarding, then uncomment it.
sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

# Else add it.
grep -Fq 'net.ipv4.ip_forward=1' /etc/sysctl.conf

if [[ "${?}" != '0' ]]; then
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi


