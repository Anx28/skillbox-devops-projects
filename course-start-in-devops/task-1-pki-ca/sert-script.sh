#!/bin/bash

set -e

EASY_RSA_DIR="$HOME/easy-rsa"

# Проверяем, установлен ли easy-rsa
if ! command -v easyrsa &> /dev/null; then
    sudo apt update
    sudo apt install easy-rsa -y
fi

# Копируем easy-rsa
mkdir -p "$EASY_RSA_DIR"
cp -r /usr/share/easy-rsa/* "$EASY_RSA_DIR/"
cd "$EASY_RSA_DIR"

# Настраиваем переменные с явным указанием Common Name
cat <<EOF > vars
set_var EASYRSA_REQ_COUNTRY    "RU"
set_var EASYRSA_REQ_PROVINCE   "Moscow"
set_var EASYRSA_REQ_CITY       "Moscow"
set_var EASYRSA_REQ_ORG        "MyCompany"
set_var EASYRSA_REQ_EMAIL      "admin@mycompany.com"
set_var EASYRSA_REQ_OU         "IT"
set_var EASYRSA_ALGO           "ec"
set_var EASYRSA_DIGEST         "sha512"
set_var EASYRSA_DN             "org"
set_var EASYRSA_REQ_CN         "MyCompany Root CA"
EOF

# Инициализируем PKI
./easyrsa init-pki

# Создаём CA в неинтерактивном режиме с предустановленными значениями
export EASYRSA_REQ_CN="MyCompany Root CA"
./easyrsa --batch build-ca nopass

echo "✅ Удостоверяющий центр настроен. Корневой сертификат: $EASY_RSA_DIR/pki/ca.crt"
echo "📄 Информация о сертификате:"
openssl x509 -text -noout -in "$EASY_RSA_DIR/pki/ca.crt" | head -20
