#!/bin/bash
set -e

echo "🔏 Signing client certificate on CA..."

cd ~/easy-rsa
REQ_PATH="/tmp/$1"

if [ -z "$1" ]; then
    echo "Usage: ./sign-client-cert.sh <path_to_req>"
    echo "Example: ./sign-client-cert.sh /tmp/alice.req"
    exit 1
fi

if [ ! -f "$REQ_PATH" ]; then
    echo "❌ $REQ_PATH not found"
    exit 1
fi

# Имя клиента — это имя файла без расширения .req
CLIENT_NAME=$(basename "$REQ_PATH" .req)

# Удаляем старые файлы, если есть
echo "🧹 Cleaning up old files..."
rm -f "pki/reqs/${CLIENT_NAME}.req"
rm -f "pki/issued/${CLIENT_NAME}.crt"

# Импортируем запрос и подписываем без подтверждения
echo "📝 Importing and signing client certificate..."
export EASYRSA_BATCH=1
./easyrsa import-req "$REQ_PATH" "$CLIENT_NAME"
./easyrsa sign-req client "$CLIENT_NAME"

echo "✅ Client certificate signed!"
echo "📄 Files created:"
echo "   - pki/issued/${CLIENT_NAME}.crt"
echo "   - pki/ca.crt"

# Копируем сертификат во временную директорию для передачи обратно
cp "pki/issued/${CLIENT_NAME}.crt" "/tmp/${CLIENT_NAME}.crt"
cp "pki/ca.crt" "/tmp/ca.crt"

echo "📦 Ready to copy back to VPN server:"
echo "   scp /tmp/${CLIENT_NAME}.crt user@vpn-server:/tmp/"
echo "   scp /tmp/ca.crt user@vpn-server:/tmp/"
