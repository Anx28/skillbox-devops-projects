# Задание 1: Удостоверяющий центр (PKI)

## 📝 Описание
Настройка удостоверяющего центра с использованием Easy-RSA для автоматической генерации корневых и клиентских сертификатов.

## 🎯 Цели
- Развертывание удостоверяющего центра
- Автоматизация процесса с помощью bash-скриптов
- Создание deb-пакета для распространения конфигурации

## 🛠️ Технологии
- Easy-RSA 3
- OpenSSL
- Bash scripting
- Debian packaging



## 🚀 Использование

### Способ 1: Использование Deb пакета (рекомендуется)
```bash
# Скачать и установить пакет
wget https://github.com/Anx28/skillbox-devops-projects/raw/main/course-start-in-devops/task-1-pki-ca/scripts/pki-ca-setup.deb
sudo dpkg -i pki-ca-setup.deb

# Запустить настройку удостоверяющего центра
setup-ca
```

### Способ 2: использовать скрипт
```
# Скачать скрипт
wget https://raw.githubusercontent.com/Anx28/skillbox-devops-projects/main/course-start-in-devops/task-1-pki-ca/scripts/sert-script.sh

# Сделать исполняемым и запустить
chmod +x sert-script.sh
./sert-script.sh
```

### Проверка результата
```
# Проверить созданный сертификат
openssl x509 -text -noout -in ~/easy-rsa/pki/ca.crt | grep -E "(Issuer|Subject|Not Before|Not After)"
```


📊 Результаты

✅ Создан корневой сертификат в ~/easy-rsa/pki/ca.crt

✅ Настроен удостоверяющий центр

✅ Автоматизирован процесс установки

✅ Создан deb-пакет для распространения
