#!/bin/bash
# auto-scp-sign.sh
# Скрипт копирует CSR на CA, подписывает его и возвращает crt + ca.crt
# Usage: ./auto-scp-sign.sh /path/to/client.req
# Переменные можно менять в начале скрипта.

set -euo pipefail
IFS=$'\n\t'

# -----------------------
# Настройки (меняйте тут)
# -----------------------
CA_USER="ubuntu"                      # пользователь на CA сервере
CA_HOST="129.213.181.181"              # IP или домен CA сервера
CA_SSH_KEY="/root/.ssh/id_rsa"       # путь к приватному ключу для ssh/scp
REMOTE_EASYRSA_DIR="~/easy-rsa"        # путь к easy-rsa на CA (удалённый)
REMOTE_TMP="/tmp"                      # временная директория на CA
LOCAL_TMP="/tmp"                       # временная директория на локальной машине
# -----------------------

# Проверки входных параметров
if [ $# -ne 1 ]; then
  echo "Usage: $0 /path/to/client.req"
  exit 2
fi

REQ_PATH="$1"
if [ ! -f "$REQ_PATH" ]; then
  echo "❌ CSR file not found: $REQ_PATH"
  exit 3
fi

CLIENT_NAME="$(basename "$REQ_PATH" .req)"
REMOTE_REQ_PATH="$REMOTE_TMP/${CLIENT_NAME}.req"
REMOTE_CRT_PATH="$REMOTE_TMP/${CLIENT_NAME}.crt"
REMOTE_CA_CRT_PATH="$REMOTE_TMP/ca.crt"
LOCAL_CRT_PATH="$LOCAL_TMP/${CLIENT_NAME}.crt"
LOCAL_CA_CRT_PATH="$LOCAL_TMP/ca.crt"

SSH_OPTS="-i ${CA_SSH_KEY} -o StrictHostKeyChecking=accept-new -o BatchMode=yes"

echo "🔎 Info:"
echo "  Client name: $CLIENT_NAME"
echo "  CSR local : $REQ_PATH"
echo "  CA host   : ${CA_USER}@${CA_HOST}"
echo ""

# 1) Копируем CSR на CA
echo "📤 Copy CSR to CA: ${CA_USER}@${CA_HOST}:${REMOTE_REQ_PATH}"
scp $SSH_OPTS "$REQ_PATH" "${CA_USER}@${CA_HOST}:${REMOTE_REQ_PATH}"

# 2) Выполняем подпись на CA через SSH
#    Будем:
#      - удалить старые записи (если есть)
#      - импортировать запрос
#      - подписать в batch-режиме (EASYRSA_BATCH=1)
#      - скопировать результат в /tmp (удалённый)

echo "🔏 Remote signing on CA..."

ssh $SSH_OPTS "${CA_USER}@${CA_HOST}" bash -s "$CLIENT_NAME" "$REMOTE_REQ_PATH" "$REMOTE_TMP" "$REMOTE_EASYRSA_DIR" <<'REMOTE_EOF'
set -euo pipefail

CLIENT_NAME="$1"
REMOTE_REQ_PATH="$2"
REMOTE_TMP="$3"
EASYRSA_DIR="$4"

export EASYRSA_BATCH=1
cd "$EASYRSA_DIR" || { echo "❌ easy-rsa dir not found: $EASYRSA_DIR"; exit 10; }

# Удаляем старые файлы, если они остались
rm -f "pki/reqs/${CLIENT_NAME}.req" "pki/issued/${CLIENT_NAME}.crt"

./easyrsa import-req "$REMOTE_REQ_PATH" "$CLIENT_NAME"
./easyrsa sign-req client "$CLIENT_NAME"

cp "pki/issued/${CLIENT_NAME}.crt" "${REMOTE_TMP}/${CLIENT_NAME}.crt"
cp "pki/ca.crt" "${REMOTE_TMP}/ca.crt"

echo "✅ Remote signing finished. Created:"
echo "   - ${REMOTE_TMP}/${CLIENT_NAME}.crt"
echo "   - ${REMOTE_TMP}/ca.crt"
REMOTE_EOF


# 3) Скачиваем обратно подписанные файлы
echo "📥 Fetch signed certificate and CA cert back to local machine"
scp $SSH_OPTS "${CA_USER}@${CA_HOST}:${REMOTE_CRT_PATH}" "${LOCAL_CRT_PATH}"
scp $SSH_OPTS "${CA_USER}@${CA_HOST}:${REMOTE_CA_CRT_PATH}" "${LOCAL_CA_CRT_PATH}"

echo "✅ Files fetched:"
ls -l "$LOCAL_CRT_PATH" "$LOCAL_CA_CRT_PATH" || true

# 4) (опционально) Переместить в /etc/openvpn/clients и /etc/openvpn
# Пользователь решает, но можно предложить автоматическую копию — спросим:
read -rp "💡 Copy ${CLIENT_NAME}.crt -> /etc/openvpn/clients/ and ca.crt -> /etc/openvpn/? [y/N]: " RESP
if [[ "$RESP" =~ ^[Yy]$ ]]; then
  sudo mkdir -p /etc/openvpn/clients
  sudo mv -f "$LOCAL_CRT_PATH" "/etc/openvpn/clients/${CLIENT_NAME}.crt"
  sudo mv -f "$LOCAL_CA_CRT_PATH" /etc/openvpn/ca.crt
  echo "✅ Files moved and CA updated in /etc/openvpn/"
fi

echo "🎉 Done. Client certificate is ready: $LOCAL_CRT_PATH"
echo "    CA cert: $LOCAL_CA_CRT_PATH"
