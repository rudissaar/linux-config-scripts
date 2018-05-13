#!/usr/bin/env bash

OPENVPN_SERVER_DIR='/etc/openvpn/server'

GATEWAY_INTERFACE=''
OPENVPN_NETWORK='10.8.0.0'
OPENVPN_NETMASK='255.255.255.0'
OPENVPN_PROTOCOL='udp'
OPENVPN_PORT=1194

USE_SAME_NAMESERVERS_AS_HOST=0
NAMESERVER_1='8.8.8.8'
NAMESERVER_2='8.8.4.4'

CRL_VERIFY=0
LZO_COMPRESSION=1

EDIT_VARS=0

RUN_FIREWALL_RULES=0

if [[ "${UID}" != '0' ]]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
dnf update -y
dnf install -y openvpn firewalld easy-rsa openssl net-tools sed

# Make sure OpenVPN server directory exists.
if [[ ! -d "${OPENVPN_SERVER_DIR}" ]]; then
    mkdir -p "${OPENVPN_SERVER_DIR}"
fi

# Move example configuration file to OpenVPN's directory.
cp /usr/share/doc/openvpn/sample/sample-config-files/server.conf "${OPENVPN_SERVER_DIR}"

# Copy Easy RSA files to OpenVPN directory.
if [[ ! -d "${OPENVPN_SERVER_DIR}/easy-rsa" ]]; then
    mkdir -p "${OPENVPN_SERVER_DIR}/easy-rsa"
fi

cp -r /usr/share/easy-rsa/3/* "${OPENVPN_SERVER_DIR}/easy-rsa/"
cp /usr/share/doc/easy-rsa/vars.example "${OPENVPN_SERVER_DIR}/easy-rsa/vars"

# Edit vars with your default text editor, using vi as fallback.
if [[ "${EDIT_VARS}" = '1' ]]; then
    ${EDITOR:-vi} "${OPENVPN_SERVER_DIR}/easy-rsa/vars"
fi

# Generate keys.
cd "${OPENVPN_SERVER_DIR}/easy-rsa"
./easyrsa init-pki
touch "${OPENVPN_SERVER_DIR}/easy-rsa/pki/index.txt.attr"

# Generate new Diffie-Hellman key.
./easyrsa gen-dh
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/dh.pem" "${OPENVPN_SERVER_DIR}/dh2048.pem"

# Generate CA key.
echo | ./easyrsa build-ca nopass
cp "${OPENVPN_SERVER_DIR}/easy-rsa/pki/ca.crt" "${OPENVPN_SERVER_DIR}"

# Generate Server key.
./easyrsa build-server-full server nopass
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/issued/server.crt" "${OPENVPN_SERVER_DIR}"
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/private/server.key" "${OPENVPN_SERVER_DIR}"

# Generate crl.pem file.
if [[ "${CRL_VERIFY}" = '1' ]]; then
    if [[ ! -f "${OPENVPN_SERVER_DIR}/easy-rsa/pki/crl.pem" ]]; then
        ./easyrsa gen-crl
    fi
fi

# Generate TLS Auth key.
openvpn --genkey --secret "${OPENVPN_SERVER_DIR}/ta.key"

cd - 1> /dev/null

# Change Port if you specified new one.
if [[ "${OPENVPN_PORT}" != '1194' ]]; then
    sed -i '/^port 1194/s/1194/'${OPENVPN_PORT}'/' "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Change Network if you specified new one.
if [[ "${OPENVPN_NETWORK}" != '10.8.0.0' ]]; then
    sed -i '/^server 10.8.0.0/s/10.8.0.0/'${OPENVPN_NETWORK}'/' "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Change Netmask if you specified new one.
if [[ "${OPENVPN_NETMASK}" != '255.255.255.0' ]]; then
    sed -i \
       '/^server '${OPENVPN_NETWORK}' 255.255.255.0/s/ 255.255.255.0/ '${OPENVPN_NETMASK}'/' \
        "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Uncomment redirect-gateway line.
sed -i '/;push "redirect-gateway def1 bypass-dhcp"/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"

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
sed -i \
    's/^;push "dhcp-option DNS .*/push "dhcp-option DNS '${NAMESERVER_2}'"/' \
    "${OPENVPN_SERVER_DIR}/server.conf"

sed -i -r \
    '0,/dhcp-option DNS '${NAMESERVER_2}'/s/'${NAMESERVER_2}'/'${NAMESERVER_1}'/' \
    "${OPENVPN_SERVER_DIR}/server.conf"

# Enable CRL (Certificate Revocation List).
if [[ "${CRL_VERIFY}" = '1' ]]; then
    grep -Fq 'crl-verify' "${OPENVPN_SERVER_DIR}/server.conf"

    if [[ "${?}" != '0' ]]; then
        echo -e \
            "\n\n# Use certificate revocation list." \
            >> "${OPENVPN_SERVER_DIR}/server.conf"

        echo \
            "crl-verify ${OPENVPN_SERVER_DIR}/easy-rsa/pki/crl.pem" \
            >> "${OPENVPN_SERVER_DIR}/server.conf"
    fi
fi

# Enable LZO compression.
if [[ "${LZO_COMPRESSION}" = '1' ]]; then
    sed -i '/;comp-lzo/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Uncomment user and group lines.
sed -i '/;user nobody/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"
sed -i '/;group nobody/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"

# Enable IPv4 forward if not enabled.
echo -n 1 > /proc/sys/net/ipv4/ip_forward

# If sysctl.conf file contains line for forwarding, then uncomment it.
sed -i '/#net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf

# Else add it.
grep -Fq 'net.ipv4.ip_forward=1' /etc/sysctl.conf

if [[ "${?}" != '0' ]]; then
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
fi

# Identify default network interface.
if [[ -z "${GATEWAY_INTERFACE}" ]]; then
    GATEWAY_INTERFACE="$(echo $(route | grep default) | cut -d ' ' -f 8)"

    if [[ -z "${GATEWAY_INTERFACE}" ]]; then
        echo '> Unable to identify default Network Interface, please define it manually.'
        exit 1
    fi
fi

# Active firewall rules.
if [[ "${RUN_FIREWALL_RULES}" = '1' ]]; then
    systemctl enable firewalld
    systemctl restart firewalld

    firewall-cmd --zone=public --change-interface=${GATEWAY_INTERFACE}
    firewall-cmd --add-masquerade
    firewall-cmd --add-port=${OPENVPN_PORT}/${OPENVPN_PROTOCOL}

    firewall-cmd --direct --passthrough ipv4 \
        -t nat -A POSTROUTING \
        -s ${OPENVPN_NETWORK}/${OPENVPN_NETMASK} \
        -o ${GATEWAY_INTERFACE} -j MASQUERADE

    firewall-cmd --runtime-to-permanent
else
    echo '> In order to complete installation you have to apply firewall rules:'
    echo "firewall-cmd --zone=public --change-interface=${GATEWAY_INTERFACE}"
    echo 'firewall-cmd --add-masquerade'
    echo "firewall-cmd --add-port=${OPENVPN_PORT}/${OPENVPN_PROTOCOL}"
    echo -n "firewall-cmd --direct --passthrough ipv4 "
    echo -n "-t nat -A POSTROUTING -s ${OPENVPN_NETWORK}/${OPENVPN_NETMASK} "
    echo "-o ${GATEWAY_INTERFACE} -j MASQUERADE"
    echo 'firewall-cmd --runtime-to-permanent'
fi

# Enable OpenVPN service.
systemctl enable openvpn-server@server.service
systemctl restart openvpn-server@server.service

