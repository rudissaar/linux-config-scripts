#!/usr/bin/env bash

OPENVPN_NETWORK='10.8.0.0'
OPENVPN_PROTOCOL='udp'
OPENVPN_PORT=1194

USE_SAME_NAMESERVERS_AS_HOST=0
NAMESERVER_1='8.8.8.8'
NAMESERVER_2='8.8.4.4'

LZO_COMPRESSION=1

RUN_UFW_FORWARD_POLICY=1
RUN_UFW_NAT=1
RUN_UFW_RULES=0
RUN_UFW_RULES_DEFAULT_SSH=1

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
apt-get update -y
apt-get install -y openvpn easy-rsa openssl ufw sed

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
sed -i 's/^;push "dhcp-option DNS .*/push "dhcp-option DNS '${NAMESERVER_2}'"/' /etc/openvpn/server.conf
sed -i -r '0,/dhcp-option DNS '${NAMESERVER_2}'/s/'${NAMESERVER_2}'/'${NAMESERVER_1}'/' /etc/openvpn/server.conf

if [[ "${LZO_COMPRESSION}" = '1' ]]; then
    sed -i '/;comp-lzo/s/^;//g' /etc/openvpn/server.conf
fi

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

# Change UFW's default forward policy.
if [[ "${RUN_UFW_FORWARD_POLICY}" = '1' ]]; then
    sed -i '/^DEFAULT_FORWARD_POLICY="DROP"$/s/DROP/ACCEPT/' /etc/default/ufw
fi

# Active NAT for OpenVPN subnet.
if [[ "${RUN_UFW_NAT}" = '1' ]]; then
    BLOCK="\n# NAT rules for OpenVPN server.\n"
    BLOCK="${BLOCK}*nat\n"
    BLOCK="${BLOCK}:POSTROUTING ACCEPT [0.0]\n"
    BLOCK="${BLOCK}-A POSTROUTING -s ${OPENVPN_NETWORK}/24 -o eth0 -j MASQUERADE\n"
    BLOCK="${BLOCK}COMMIT\n"

    echo "$BLOCK"
    #sed -i '0,/^$/s/^$/'"${BLOCK}"'/' /etc/ufw/before.rules
fi

# Block that either gives information about firewall rules that you should apply, or just applies them.
if [[ "${RUN_UFW_RULES}" = '1' ]]; then
    if [[ "${RUN_UFW_RULES_DEFAULT_SSH}" = '1' ]]; then
        ufw allow ssh
    fi

    ufw allow proto ${OPENVPN_PROTOCOL} to 0.0.0.0/0 port ${OPENVPN_PORT}
    ufw enable
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo -n 'ufw allow ssh '
    echo '# Or any other rule that you use to connect to this machine.'
    echo 'ufw allow proto '${OPENVPN_PROTOCOL}' to 0.0.0.0/0 port '${OPENVPN_PORT}
    echo 'ufw enable'
fi

