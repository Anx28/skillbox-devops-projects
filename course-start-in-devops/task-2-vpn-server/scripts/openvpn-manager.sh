#!/bin/bash
#  Description: Automates setup of OpenVPN server and certificate lifecycle.

set -e

OPENVPN_DIR="/etc/openvpn"
EASYRSA_DIR="$OPENVPN_DIR/easy-rsa"
CLIENTS_DIR="$OPENVPN_DIR/clients"
LOG_DIR="/var/log/openvpn"

function check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root (use sudo)."
    exit 1
  fi
}

function install_openvpn() {
  echo "🚀 Installing OpenVPN and Easy-RSA..."
  apt update && apt install -y openvpn easy-rsa curl iptables-persistent

  mkdir -p "$EASYRSA_DIR" "$CLIENTS_DIR" "$LOG_DIR"
  cp -r /usr/share/easy-rsa/* "$EASYRSA_DIR"
  chown -R root:root "$EASYRSA_DIR"

  cd "$EASYRSA_DIR"
  cat << EOF > vars
set_var EASYRSA_REQ_COUNTRY    "RU"
set_var EASYRSA_REQ_PROVINCE   "Moscow"
set_var EASYRSA_REQ_CITY       "Moscow"
set_var EASYRSA_REQ_ORG        "MyCompany"
set_var EASYRSA_REQ_EMAIL      "admin@myvpn.local"
set_var EASYRSA_REQ_OU         "IT"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
set_var EASYRSA_DN             "org"
EOF

  echo "✅ Installation completed!"
}

function gen_server_cert() {
  echo "🔐 Generating server key and CSR..."
  cd "$EASYRSA_DIR"
  ./easyrsa init-pki
  ./easyrsa gen-req server nopass

  cp pki/reqs/server.req /tmp/server.req
  cp pki/private/server.key "$OPENVPN_DIR/server.key"

  echo "✅ Server request created: /tmp/server.req"
  echo "📤 Copy it to CA server and sign there, e.g."
  echo "   scp /tmp/server.req user@ca-server:/tmp/"
  echo "   ./sign-server-cert-simple.sh /tmp/server.req"
  echo "📥 Then copy back signed files: server.crt, ca.crt"
}

function configure_openvpn() {
  echo "⚙️ Configuring OpenVPN server..."
  SERVER_CONF="$OPENVPN_DIR/server.conf"

  if [ ! -f "$OPENVPN_DIR/server.crt" ] || [ ! -f "$OPENVPN_DIR/ca.crt" ]; then
    echo "❌ Missing server.crt or ca.crt in $OPENVPN_DIR. Copy them before running configure."
    exit 1
  fi

  mkdir -p "$LOG_DIR"
  chown nobody:nogroup "$LOG_DIR"

  cat << EOF > "$SERVER_CONF"
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh none
ecdh-curve prime256v1
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-GCM
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status $LOG_DIR/openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

  echo "🌐 Enabling IP forwarding and NAT..."
  sed -i 's/^#*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  sysctl -p

  # Определяем внешний интерфейс
  EXT_IF=$(ip route | grep default | awk '{print $5}' | head -n 1)
  if [ -z "$EXT_IF" ]; then
    echo "⚠️ Could not detect external interface automatically."
    read -p "Enter external interface name (e.g. eth0): " EXT_IF
  fi

  # Настраиваем NAT
  iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$EXT_IF" -j MASQUERADE
  netfilter-persistent save
  netfilter-persistent reload

  systemctl enable openvpn@server
  systemctl start openvpn@server

  echo "✅ OpenVPN configured and started!"
  echo "🌐 Server IP: $(hostname -I | awk '{print $1}')"
  echo "📊 Check status: sudo systemctl status openvpn@server"
}

function gen_client_cert() {
  if [ -z "$1" ]; then
    echo "Usage: $0 --gen-client <client_name>"
    exit 1
  fi
  CLIENT_NAME="$1"
  echo "👤 Generating client key and CSR for $CLIENT_NAME..."

  cd "$EASYRSA_DIR"
  ./easyrsa gen-req "$CLIENT_NAME" nopass

  cp pki/reqs/${CLIENT_NAME}.req /tmp/${CLIENT_NAME}.req
  cp pki/private/${CLIENT_NAME}.key "$CLIENTS_DIR/${CLIENT_NAME}.key"

  echo "✅ Client request created: /tmp/${CLIENT_NAME}.req"
  echo "📤 Copy it to CA server to sign, e.g."
  echo "   scp /tmp/${CLIENT_NAME}.req user@ca-server:/tmp/"
  echo "   ./sign-client-cert.sh /tmp/${CLIENT_NAME}.req"
  echo "📥 Then copy back signed file: ${CLIENT_NAME}.crt"
}

function package_client() {
  if [ -z "$1" ]; then
    echo "Usage: $0 --package-client <client_name>"
    exit 1
  fi
  CLIENT_NAME="$1"
  CLIENT_KEY="$CLIENTS_DIR/${CLIENT_NAME}.key"
  CLIENT_CRT="$CLIENTS_DIR/${CLIENT_NAME}.crt"
  CA_CRT="$OPENVPN_DIR/ca.crt"
  OUTPUT_FILE="$CLIENTS_DIR/${CLIENT_NAME}.ovpn"

  if [ ! -f "$CLIENT_KEY" ] || [ ! -f "$CLIENT_CRT" ] || [ ! -f "$CA_CRT" ]; then
    echo "❌ Missing client or CA certificates. Ensure ${CLIENT_NAME}.crt, ${CLIENT_NAME}.key, and ca.crt exist."
    exit 1
  fi

  SERVER_IP=$(hostname -I | awk '{print $1}')
  cat << EOF > "$OUTPUT_FILE"
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3

<ca>
$(cat "$CA_CRT")
</ca>
<cert>
$(cat "$CLIENT_CRT")
</cert>
<key>
$(cat "$CLIENT_KEY")
</key>
EOF

  echo "✅ Client package created: $OUTPUT_FILE"
  echo "📤 Distribute this file to your client securely."
}

function show_status() {
  systemctl status openvpn@server --no-pager
}

function show_help() {
  echo "\nOpenVPN Unified Manager (gptonline.ai)"
  echo "Usage: $0 [command]"
  echo "\nCommands:"
  echo "  --install            Install OpenVPN and Easy-RSA"
  echo "  --gen-server         Generate server key and CSR"
  echo "  --configure          Configure and start OpenVPN"
  echo "  --gen-client NAME    Generate client CSR and key"
  echo "  --package-client NAME Create .ovpn package for client"
  echo "  --status             Show OpenVPN server status"
  echo "\nExample:"
  echo "  sudo bash $0 --install"
  echo "  sudo bash $0 --gen-server"
  echo "  sudo bash $0 --configure"
  echo "  sudo bash $0 --gen-client alice"
  echo "  sudo bash $0 --package-client alice"
}

check_root

case "$1" in
  --install)
    install_openvpn
    ;;
  --gen-server)
    gen_server_cert
    ;;
  --configure)
    configure_openvpn
    ;;
  --gen-client)
    gen_client_cert "$2"
    ;;
  --package-client)
    package_client "$2"
    ;;
  --status)
    show_status
    ;;
  *)
    show_help
    ;;
esac
