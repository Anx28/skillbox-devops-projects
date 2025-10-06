# OpenVPN Unified Manager

Автоматизированный Bash-скрипт для установки, настройки и управления OpenVPN‑сервером с использованием Easy‑RSA и внешнего удостоверяющего центра (CA).

> 📘 Репозиторий проекта: [Anx28 / skillbox-devops-projects / task‑2‑vpn‑server / scripts](https://github.com/Anx28/skillbox-devops-projects/tree/main/course-start-in-devops/task-2-vpn-server/scripts)

---

## 🧩 Возможности

* Полная автоматическая установка OpenVPN и Easy‑RSA
* Генерация серверного ключа и CSR для внешнего CA
* Генерация клиентских ключей и запросов
* Настройка OpenVPN‑сервера, IP‑форвардинга и NAT
* Создание готовых `.ovpn`‑профилей клиентов
* Полностью автономная работа с внешним удостоверяющим центром

---

## ⚙️ Установка

```bash
sudo apt update && sudo apt install git -y
git clone https://github.com/Anx28/skillbox-devops-projects.git
cd skillbox-devops-projects/course-start-in-devops/task-2-vpn-server/scripts
sudo chmod +x openvpn-manager.sh
```

---

## 🚀 Использование

### 1. Установка OpenVPN и Easy‑RSA

```bash
sudo bash openvpn-manager.sh --install
```

### 2. Генерация серверного CSR

```bash
sudo bash openvpn-manager.sh --gen-server
```

> ⚠️ Скопируйте `/tmp/server.req` на CA‑сервер и подпишите его с помощью `sign-server-cert-simple.sh`. Затем верните `server.crt` и `ca.crt` обратно на VPN‑сервер.

### 3. Настройка и запуск OpenVPN

```bash
sudo bash openvpn-manager.sh --configure
```

Скрипт:

* создаёт `/etc/openvpn/server.conf`
* включает IP‑форвардинг и NAT
* запускает службу OpenVPN (`systemctl enable/start openvpn@server`)

### 4. Генерация клиентского CSR

```bash
sudo bash openvpn-manager.sh --gen-client alice
```

> ⚠️ Скопируйте `/tmp/alice.req` на CA‑сервер, подпишите и верните `alice.crt` + `ca.crt` обратно.

### 5. Создание клиентского `.ovpn`‑профиля

```bash
sudo bash openvpn-manager.sh --package-client alice
```

После выполнения появится готовый файл:

```
/etc/openvpn/clients/alice.ovpn
```

Его можно сразу импортировать в OpenVPN GUI или мобильный клиент.

### 6. Проверка статуса сервера

```bash
sudo bash openvpn-manager.sh --status
```

---

## 🧠 Пример полного цикла

| Этап | Сервер | Команда                                      |
| ---- | ------ | -------------------------------------------- |
| 1    | VPN    | `--install`                                  |
| 2    | VPN    | `--gen-server`                               |
| 3    | CA     | `sign-server-cert-simple.sh /tmp/server.req` |
| 4    | VPN    | `--configure`                                |
| 5    | VPN    | `--gen-client alice`                         |
| 6    | CA     | `sign-client-cert.sh /tmp/alice.req`         |
| 7    | VPN    | `--package-client alice`                     |

---

## 📂 Структура проекта

```
course-start-in-devops/
└── task-2-vpn-server/
    └── scripts/
        ├── openvpn-manager.sh          # Основной скрипт установки и настройки
        ├── sign-server-cert-simple.sh  # Подпись серверного CSR (на CA)
        ├── sign-client-cert.sh         # Подпись клиентских CSR (на CA)
        └── README.md                   # Документация проекта
```

---

## 🛡️ Безопасность

* Не храните приватные ключи на CA и VPN‑сервере одновременно.
* Передавайте CSR/CRT‑файлы только по защищённым каналам (`scp`, `rsync`, `VPN`).
* Проверяйте содержимое сертификатов перед подписью.

---

## 💬 Поддержка

Проект разработан в рамках курса Skillbox *«Start in DevOps»*.

---

