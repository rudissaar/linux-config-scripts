#!/usr/bin/env bash

GATEWAY_INTERFACE=''
OPENVPN_NETWORK='10.8.0.0'
OPENVPN_NETMASK='255.255.255.0'
OPENVPN_PROTOCOL='udp'
OPENVPN_PORT=1195

USE_SAME_NAMESERVERS_AS_HOST=0
NAMESERVER_1='8.8.8.8'
NAMESERVER_2='8.8.4.4'

CRL_VERIFY=0
LZO_COMPRESSION=1

EDIT_VARS=0

RUN_FIREWALL_RULES=0
RUN_FIREWALL_RULES_DEFAULT_SSH=1

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf update -y
dnf install -y openvpn easy-rsa openssl net-tools sed

# Make sure /etc/openvpn directory exists.
if [[ ! -d /etc/openvpn ]]; then
    mkdir /etc/openvpn
fi

# Remove useless folders if they exist and are empty.
rmdir /etc/openvpn/server 1> /dev/null 2>&1
rmdir /etc/openvpn/client 1> /dev/null 2>&1

# Move example configuration file to OpenVPN's directory.
cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf /etc/openvpn/

# Copy Easy RSA files to OpenVPN directory.
if [[ ! -d /etc/openvpn/easy-rsa ]]; then
    mkdir /etc/openvpn/easy-rsa
fi

cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
cp /usr/share/doc/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars

# Edit vars with your default text editor, using vi as fallback.
if [[ "${EDIT_VARS}" = '1' ]]; then
    ${EDITOR:-vi} /etc/openvpn/easy-rsa/vars
fi

# Generate keys.
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
touch /etc/openvpn/easy-rsa/pki/index.txt.attr

# Generate new Diffie-Hellman key.
./easyrsa gen-dh
mv /etc/openvpn/easy-rsa/keys/dh.pem /etc/openvpn/

# Generate CA key.
echo | ./easyrsa build-ca nopass
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/

# Generate Server key.
./easyrsa build-server-full server nopass
mv /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/
mv /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/

# Generate crl.pem file.
if [[ "${CRL_VERIFY}" = '1' ]]; then
    if [[ ! -f /etc/openvpn/easy-rsa/pki/crl.pem ]]; then
	./easyrsa gen-crl
    fi
fi

# Generate TLS Auth key.
openvpn --genkey --secret /etc/openvpn/ta.key

cd - 1> /dev/null

# Change Port if you specified new one.
if [[ "${OPENVPN_PORT}" != '1194' ]]; then
    sed -i '/^port 1194/s/1194/'${OPENVPN_PORT}'/' /etc/openvpn/server.conf
fi

# Change Network if you specified new one.
if [[ "${OPENVPN_NETWORK}" != '10.8.0.0' ]]; then
    sed -i '/^server 10.8.0.0/s/10.8.0.0/'${OPENVPN_NETWORK}'/' /etc/openvpn/server.conf
fi

# Change Netmask if you specified new one.
if [[ "${OPENVPN_NETMASK}" != '255.255.255.0' ]]; then
    sed -i '/^server '${OPENVPN_NETWORK}' 255.255.255.0/s/ 255.255.255.0/ '${OPENVPN_NETMASK}'/' /etc/openvpn/server.conf
fi

# Uncomment redirect-gateway line.
sed -i '/;push "redirect-gateway def1 bypass-dhcp"/s/^;//g' /etc/openvpn/server.conf

# Try to fetch nameservers from /etc/resolv.conf
if [[ "${USE_SAME_NAMESERVERS_AS_HOST}" = '1' ]]; then
    NAMESERVERS=($(cat /etc/resolv.conf | grep nameserver | head -n 2 | cut -d ' ' -f 2))

    if [[ ${#NAMESERVERS[@]} -lt 1 ]]; then
        echo "> Unable to identify Host's Nameservers, using fallback."
    elif [[ ${#NAMESERVERS[@]} -eq 1 ]]; then
        NAMESERVER_1="${NAMESERVERS[0]}"
    else
        NAMESERVER_1="${NAMESERVERS[0]}"
        NAMESERVER_2="${NAMESERVERS[1]}"
    fi
fi

# Uncomment and set DNS servers.
sed -i 's/^;push "dhcp-option DNS .*/push "dhcp-option DNS '${NAMESERVER_2}'"/' /etc/openvpn/server.conf
sed -i -r '0,/dhcp-option DNS '${NAMESERVER_2}'/s/'${NAMESERVER_2}'/'${NAMESERVER_1}'/' /etc/openvpn/server.conf

# Enable CRL (Certificate Revocation List).
if [[ "${CRL_VERIFY}" = '1' ]]; then
    grep -Fq 'crl-verify' /etc/openvpn/server.conf

    if [[ "${?}" != '0' ]]; then
        echo -e "\n\n# Use certificate revocation list." >> /etc/openvpn/server.conf
        echo 'crl-verify /etc/openvpn/easy-rsa/pki/crl.pem' >> /etc/openvpn/server.conf
    fi
fi

# Enable LZO compression.
if [[ "${LZO_COMPRESSION}" = '1' ]]; then
    sed -i '/;comp-lzo/s/^;//g' /etc/openvpn/server.conf
fi

# Uncomment user and group lines.
sed -i '/;user nobody/s/^;//g' /etc/openvpn/server.conf
sed -i '/;group nobody/s/^;//g' /etc/openvpn/server.conf

# Enable IPv4 forward if not enabled.
echo -n 1 > /proc/sys/net/ipv4/ip_forward

# If sysctl.conf file contains line for forwarding, then uncomment it.
sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

# Else add it.
grep -Fq 'net.ipv4.ip_forward=1' /etc/sysctl.conf

if [[ "${?}" != '0' ]]; then
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi
