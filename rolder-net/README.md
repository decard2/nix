# README.md

## Скрипт

### Что делает

1. Провеяет SSH-подключения к серверу
2. Валидирует конфигурации flake
3. Загруэает NixOS в память целевой системы (kexec)
4. Разметку диска и форматирование
5. Установку NixOS с выбранной конфигурацией
6. Перезагружает в новую систему

### Использование

#### Запуск

```bash
./install.sh HOSTNAME TARGET_IP [PASSWORD]
```

#### Параметры

```bash
./install.sh [ОПЦИИ] HOSTNAME TARGET_IP [PASSWORD]

Аргументы:
  HOSTNAME         Имя хоста для сервера (например, frankfurt, panel)
  TARGET_IP        IP-адрес целевого сервера
  PASSWORD         Пароль для SSH-подключения (опционально)

Опции:
  -u, --user USER     SSH-пользователь (по умолчанию: root)
  -p, --port PORT     SSH-порт для установки (по умолчанию: 22)
  -h, --help          Показать справку
```

## Обслуживание

### Подключение к серверу

```bash
ssh -p 4444 rolder@TARGET_IP
```

### Обновление

```bash
# Локально на сервере
sudo nixos-rebuild switch --flake github:decard2/nix?dir=rolder-net#hostname

# Удаленно из локальной директории
cd rolder-net
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --flake .#hostname --target-host rolder@TARGET_IP --ask-sudo-password

# Удаленно из GitHub
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --flake github:decard2/nix?dir=rolder-net#hostname --target-host rolder@TARGET_IP --ask-sudo-password
```

## Развертывание

1. **Подготовка** - в флейке изменить параметры панели и нод, поменять конфигурации нод и хостов
2. **Переустановить ОС** у провайдера - Debian 11, целевой пароль для root
3. **Установить панель** скриптом: `./install.sh panel TARGET_IP ROOT_PASSWORD`
4. **Настроить API** - зарегистрироваться в панели, сгенерировать API-ключ, заменить в `common.nix`, обновить сервер панели
5. **Обновить инбаунды** - взять новые UUID инбаундов из панели, поменять в конфигах нод и пользователей, обновить сервер
6. **Установить ноды** скриптом: `./install.sh hostname TARGET_IP ROOT_PASSWORD`
