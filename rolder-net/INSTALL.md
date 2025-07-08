# INSTALL.md - Инструкция по установке rolder-net

## Требования

- Nix с включенными flakes
- Установленный `sshpass`
- Доступ по SSH к целевому серверу (порт 22)
- Debian/Ubuntu на целевом сервере

## Быстрая установка

### Установка панели или ноды

```bash
./install.sh HOSTNAME TARGET_IP [PASSWORD]
```

**Пример:**

```bash
./install.sh frankfurt 37.221.125.150 'MyPassword123'
# или без пароля в команде (запросит пароль)
./install.sh frankfurt 37.221.125.150
```

### Параметры скрипта

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

## Что происходит при установке

1. Проверка SSH-подключения к серверу
2. Валидация конфигурации flake
3. Загрузка NixOS в память целевой системы (kexec)
4. Разметка диска и форматирование
5. Установка NixOS с выбранной конфигурацией
6. Перезагрузка в новую систему

## После установки

### Подключение к системе

```bash
ssh -p 4444 rolder@TARGET_IP
```

**Важно**: После установки SSH работает на порту 4444, а не 22!

### Обновление системы

```bash
# Локально на сервере
sudo nixos-rebuild switch --flake github:decard2/nix?dir=rolder-net#hostname

# Удаленно из локальной директории
cd rolder-net
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --flake .#hostname --target-host rolder@TARGET_IP --ask-sudo-password

# Удаленно из GitHub
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --flake github:decard2/nix?dir=rolder-net#hostname --target-host rolder@TARGET_IP --ask-sudo-password
```
