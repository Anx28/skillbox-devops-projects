#!/bin/bash
set -e

echo "🔏 Signing server certificate on CA..."

cd ~/easy-rsa
REQ_PATH="/tmp/server.req"

# Проверяем, что запрос существует
if [ ! -f "$REQ_PATH" ]; then
    echo "❌ $REQ_PATH not found"
    echo "📁 Files in /tmp/:"
    ls -la /tmp/
    exit 1
fi

# Удаляем старые файлы
echo "🧹 Cleaning up old files..."
rm -f pki/reqs/server.req
rm -f pki/issued/server.crt

# Импортируем и подписываем
echo "📝 Importing and signing server certificate..."
export EASYRSA_BATCH=1
./easyrsa import-req "$REQ_PATH" server
./easyrsa sign-req server server



echo "✅ Server certificate signed!"
echo "📄 Files created:"
echo "   - pki/issued/server.crt"
echo "   - pki/ca.crt"

echo ""
echo "📋 Verification:"
ls -la pki/issued/server.crt
ls -la pki/ca.crt
