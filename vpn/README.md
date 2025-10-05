# Remnawave

## Установка в Google Cloud

### Подготовка

**Если вообще с 0**

1. Зарегестрировать аккаунт в Google Cloud, привязав карту банка. Создать проект.
2. Подготовить Google Cloud - gcloud init с выбором проекта, запустить API Google Cloud Compute Engine.
3. Сгенерировать ssh-ключ для доступа к серверам.
4. Зарегестрировать аккаунт в CloudFlare. Привязать домен.

**Параметры**

1. vpn/terraform/providers.tf - заменить ключь API CloudFlare и id проекта Google
2. vpn/terraform/cloudflare.tf - заменить zone_id.
3. vpn/terraform/vms.tf - заменить id проекта Google, путь к открытому ssh-ключу.
4. vpn/terraform/vms.tf - для хостов временно поменять machine_type на e2-highcpu-4

### Установка

**Слой инфраструктуры (terraform)**

1. cd vpn/terraform, terraform init (нужен vpn). Если нет vpn - export https_proxy=адрес. Нужно найти бесплатный именно HTTPS-прокси.
2. terraform plan - смотрим план. Если есть ошикби, разбираемя пока не будет.
3. terraform apply - применяем план.
4. gcloud compute instances list - смотрим EXTERNAL_IP для каждой ВМ и меняем в vpn/terraform/cloudflare.tf.
5. terraform apply - применяем план для обновления DNS.

**Слой операционных систем (nix)**

1. Панель:

- cd vpn/nix, ./install.sh -k ~/.ssh/rolder-net-gcp -u roldernet_gmail_com remnapanel rolder.net
- Проверяем в браузере, что панель ожила и предлагает зарегиться.
- Качаем последний бекап с облака - sudo remnawave-download-yandex
- Проверяем - remnawave-list-backups
- Ресторим - sudo remnawave-restore latest
- Перезагружаемся - sudo reboot

2. Хосты - ./install.sh -k ~/.ssh/rolder-net-gcp -u roldernet_gmail_com хост dns-хоста.rolder.net

### Проерка

1. Есть пользователи, в скваде количество хостов и пользователей не задвоено, сами хосты не задвоидись, ноды подключились.
2. Happ обновляет профиль, профиль соответсвует конфе, VPN работает (лучшая проверка - рилсы в интсе не стопорятся).

## Обслуживание

### Подключение к серверу

```bash
ssh -p 4444 rolder@{dns}

# Панель
ssh -p 4444 rolder@rolder.net

# Хосты
ssh -p 4444 rolder@{sw|fi}.rolder.net
```

### Обновление

```bash
# Удаленно из локальной директории
cd ~/nix/vpn/nix
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --refresh --flake .#hostname --target-host rolder@dns --ask-sudo-password

# Локально на сервере
sudo nixos-rebuild switch --refresh --flake github:decard2/nix?dir=rolder-net#hostname

# Удаленно из GitHub
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --refresh --flake github:decard2/nix?dir=rolder-net#hostname --target-host rolder@TARGET_IP --ask-sudo-password
```

### Бекапы

#### Команды

```bash
# Создать бекап вручную
sudo systemctl start remnawave-db-backup.service

# Скачать последний бекап из облака (после переустановки системы)
sudo remnawave-download-yandex

# Скачать последние 5 бекапов из облака
sudo remnawave-download-yandex 5

# Посмотреть доступные бекапы
remnawave-list-backups

# Восстановить из последнего бекапа
sudo remnawave-restore latest

# Восстановить из конкретного файла
sudo remnawave-restore /opt/remnawave/backups/remnawave_20251005_081447.dump

# Синхронизировать с облаком вручную
remnawave-sync-yandex
```

#### Расписание

- **Бекапы**: каждый день в 01:00 МСК
- **Синхронизация в облако**: автоматически при создании бекапа
- **Очистка**: локально >30 дней, в облаке >180 дней

#### Файлы

- Бекапы: `/opt/remnawave/backups/`
- Облако: `rolder-backups/rolder-net/`

##### Как это устроено

###### Компоненты

1. **backup.nix** - создание бекапов PostgreSQL
2. **restore.nix** - команды восстановления
3. **yandex-backup.nix** - синхронизация с Yandex Object Storage

###### Автоматика

- `remnawave-db-backup.timer` - ежедневный таймер бекапов
- `remnawave-yandex-backup-sync.path` - отслеживает изменения в папке бекапов
- При новом бекапе автоматически запускается `remnawave-yandex-backup-sync.service`

###### Технические детали

- Формат бекапов: PostgreSQL custom format (.dump)
- Сжатие: уровень 9
- Транспорт: rclone с S3-совместимым API
- Мониторинг для синхронизации: systemd path units + inotify

### Скрипт установки

#### Что делает

1. Провеяет SSH-подключения к серверу
2. Валидирует конфигурации flake
3. Загруэает NixOS в память целевой системы (kexec)
4. Разметку диска и форматирование
5. Установку NixOS с выбранной конфигурацией
6. Перезагружает в новую систему

#### Использование

##### Запуск

```bash
./install.sh HOSTNAME TARGET_IP [PASSWORD]

# Для GCP
./install.sh -k ~/.ssh/rolder-net-gcp -u roldernet_gmail_com remnapanel 34.51.236.162
```

##### Параметры

```bash
./install.sh [ОПЦИИ] HOSTNAME TARGET_IP [PASSWORD]

Аргументы:
  HOSTNAME         Имя хоста для сервера (например, frankfurt, panel)
  TARGET_IP        IP-адрес целевого сервера
  PASSWORD         Пароль для SSH-подключения (опционально)

Опции:
  -u, --user USER     SSH-пользователь (по умолчанию: root)
  -p, --port PORT     SSH-порт для установки (по умолчанию: 22)
  -k, --key KEY       Путь к SSH-ключу для установки в GCP
  -h, --help          Показать справку
```

## Нюансы конфигурации Remnawave

- Один инбануд - одна нода - один хост. Так управляется доступ и трафик.
- Инбаунды не могут использовать один privateKey.
