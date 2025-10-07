#!/bin/bash
# 🔁 Отправка server.req на CA, подпись и возврат сертификатов

set -euo pipefail
IFS=$'\n\t'

# === Настройки ===
CA_USER="ubuntu"                      # Пользователь на CA
CA_HOST="129.213.181.181"             # IP или домен CA
CA_SSH_KEY="${HOME}/.ssh/id_rsa"      # SSH-ключ (если доступ настроен — можно оставить по умолчанию)
CA_SIGN_SCRIPT="~/sign-srt.sh"        # Путь к твоему скрипту подписи на CA
REMOTE_TMP="/tmp"                     # Временная директория на CA
LOCAL_REQ="/tmp/server.req"           # Путь к CSR на VPN
LOCAL_OPENVPN_DIR="/etc/openvpn"      # Путь, куда сохранять сертификаты
SSH_OPTS="-i ${CA_SSH_KEY} -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
# ==================

echo "🔏 Starting automatic server certificate signing..."
echo "🌍 CA host: ${CA_USER}@${CA_HOST}"

# Проверяем наличие CSR
if [[ ! -f "$LOCAL_REQ" ]]; then
  echo "❌ Request file not found: $LOCAL_REQ"
  exit 1
fi

# Отправляем запрос на CA
echo "📤 Copying $LOCAL_REQ to ${CA_USER}@${CA_HOST}:${REMOTE_TMP}/server.req ..."
scp $SSH_OPTS "$LOCAL_REQ" ${CA_USER}@${CA_HOST}:${REMOTE_TMP}/server.req

# Подписываем на CA
echo "📝 Signing on CA using $CA_SIGN_SCRIPT ..."
ssh $SSH_OPTS ${CA_USER}@${CA_HOST} "bash $CA_SIGN_SCRIPT"

# Возвращаем результаты
echo "📥 Fetching signed certificates..."
scp $SSH_OPTS ${CA_USER}@${CA_HOST}:${REMOTE_TMP}/../easy-rsa/pki/issued/server.crt ${LOCAL_OPENVPN_DIR}/server.crt || \
scp $SSH_OPTS ${CA_USER}@${CA_HOST}:~/easy-rsa/pki/issued/server.crt ${LOCAL_OPENVPN_DIR}/server.crt

scp $SSH_OPTS ${CA_USER}@${CA_HOST}:~/easy-rsa/pki/ca.crt ${LOCAL_OPENVPN_DIR}/ca.crt

# Проверяем
echo "✅ Certificates received:"
ls -lh ${LOCAL_OPENVPN_DIR}/server.crt ${LOCAL_OPENVPN_DIR}/ca.crt

# Проверяем хэш соответствия ключа и сертификата
if [[ -f "${LOCAL_OPENVPN_DIR}/server.key" ]]; then
  echo ""
  echo "🔍 Verifying key–certificate match..."
  KEY_HASH=$(openssl pkey -in ${LOCAL_OPENVPN_DIR}/server.key -pubout 2>/dev/null | sha256sum | awk '{print $1}')
  CRT_HASH=$(openssl x509 -in ${LOCAL_OPENVPN_DIR}/server.crt -pubkey -noout 2>/dev/null | sha256sum | awk '{print $1}')
  echo "   Key : $KEY_HASH"
  echo "   Cert: $CRT_HASH"
  if [[ "$KEY_HASH" == "$CRT_HASH" ]]; then
    echo "✅ Server key matches certificate."
  else
    echo "⚠️  WARNING: Server key and certificate DO NOT match!"
  fi
fi

echo ""
echo "🎉 Done. Signed server certificate and CA imported successfully."
