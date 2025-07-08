# AGENT.md - Инструкция по работе с rolder-net флейком

## Архитектура

Это NixOS flake для развертывания инфраструктуры VPN-сервисов на базе Remnawave. Включает 2 типа серверов:

- VPN-ноды - сервера для подключения клиентов
- Panel - панель управления

## Структура файлов

### Основные файлы

- `flake.nix` - точка входа, описывает конфигурации серверов
- `common.nix` - общие настройки для всех серверов
- `hardware-common.nix` - аппаратные настройки для KVM/QEMU
- `disk-config.nix` - разметка дисков через disko

### Контейнеры

- `containers/remnanode/` - VPN-нода (порт 2222)
- `containers/remnapanel/` - панель управления (веб-интерфейс)

## Ключевые особенности

### Сеть

- SSH на порту 4444 (не 22!)
- Статические IP адреса
- Firewall включен, открыты только нужные порты

### Контейнеры

- Используется Podman (не Docker)
- Автозапуск через systemd
- Сетевое взаимодействие через host network или внутренние сети

### Remnawave Panel

Состоит из 4 контейнеров:

- `remnawave-db` - PostgreSQL
- `remnawave-redis` - Valkey (Redis)
- `remnawave-backend` - основное API
- `remnawave-angie` - reverse proxy с SSL

### Синхронизация данных

- Автоматическая синхронизация конфигов через API
- Сертификаты синхронизируются между panel и node
- Конфиги в JSON файлах: hosts.json, nodes.json, users.json, xray.json

## Важные пути

- `/opt/remnawave/` - данные панели
- `/opt/remnanode/` - данные ноды
- Конфиги в `containers/remnapanel/configs/`

## Добавление новых нод

1. В `flake.nix` добавить новую конфигурацию по шаблону:

```nix
newnode = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    hostConfig = {
      hostname = "newnode";
      serverIP = "IP_ADDRESS";
      gateway = "GATEWAY_IP";
      rolderPassword = "HASHED_PASSWORD";
      containers = [ "remnanode" ];
    };
  };
  modules = [
    disko.nixosModules.disko
    ./common.nix
    ./disk-config.nix
  ];
};
```

2. В `containers/remnapanel/configs/nodes.json` добавить запись:

```json
{
  "name": "Node Name",
  "address": "IP_ADDRESS",
  "port": 2222,
  "countryCode": "COUNTRY_CODE",
  "excludedInbounds": ["UUID_OF_EXCLUDED_INBOUND"]
}
```

## Добавление хостов

Для добавления хостов нужен UUID инбаунда из Xray конфигурации.

### Получение UUID инбаунда

Получить список всех инбаундов через API:

```bash
curl -X GET "https://rolder.net/api/inbounds" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

В ответе будет список инбаундов с их UUID, которые нужно использовать в `inboundUuid`.

### Смена API токена

API токен определен в `common.nix` в переменной `remnawave_api_token`.

### Добавление хоста

Редактировать `containers/remnapanel/configs/hosts.json`:

```json
{
  "inboundUuid": "UUID_FROM_INBOUNDS_API",
  "remark": "[Эмодзи флага страны] [Город]",
  "address": "IP_ADDRESS",
  "port": 443,
  "path": "/",
  "sni": "www.microsoft.com",
  "host": "www.microsoft.com",
  "allowInsecure": false,
  "isDisabled": false,
  "securityLayer": "TLS"
}
```

## Добавление пользователей

Редактировать `containers/remnapanel/configs/users.json`:

```json
{
  "username": "username",
  "status": "ACTIVE",
  "trafficLimitBytes": 536870912000,
  "trafficLimitStrategy": "MONTH",
  "expireAt": "2100-01-01T00:00:00.000Z",
  "activeUserInbounds": ["UUID_FROM_INBOUNDS_API"]
}
```

## Конфигурация Xray

Основная конфигурация в `containers/remnapanel/configs/xray.json`:

- Содержит inbounds (входящие соединения)
- Outbounds (исходящие соединения)
- Routing rules
- DNS настройки
