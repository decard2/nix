# Remnawave Sync Redesign

## Цель

Заменить 6 bash systemd-сервисов одним Python-скриптом с полным reconcile, dry-run и автоматическим бекапом БД.

## Решения

- **Язык:** Python (requests + stdlib)
- **Идентификация объектов:** lookup по уникальному полю (username, name, remark, uuid) — без state file
- **Удаление:** поддерживается с dry-run/apply (desired state = единственный источник правды)
- **Запуск:** systemd oneshot при boot (auto apply) + ручной запуск с --dry-run
- **Scope:** все 6 сущностей сразу

## Архитектура

Один файл `sync.py`, ~300 строк. Упаковка через `pkgs.writers.writePython3Bin`.

### CLI

```
remnawave-sync --dry-run              # показать план
remnawave-sync --apply                # бекап БД + синхронизация
remnawave-sync --apply --no-backup    # без бекапа
```

### Сущности

| Сущность | Endpoint | Key field | Операции |
|----------|----------|-----------|----------|
| config-profiles | /api/config-profiles | uuid | update |
| internal-squads | /api/internal-squads | uuid | update |
| nodes | /api/nodes | name | create, update, delete |
| hosts | /api/hosts | remark | create, update, delete |
| users | /api/users | username | create, update, delete |
| additional-settings | /api/subscription-settings | (синглтон) | update |

Порядок: profiles -> squads -> nodes + hosts -> users -> settings.

### Reconcile-алгоритм

Для каждой сущности:
1. GET текущее состояние из API
2. Построить маппинг key_value -> existing_object
3. Для каждого объекта из JSON: PATCH (если есть) или POST (если нет и create в ops)
4. Для каждого объекта в API, которого нет в JSON: DELETE (если delete в ops)

config-profiles и squads — только update (создаются панелью, удалять нельзя).
additional-settings — синглтон, всегда GET uuid + PATCH.

### Бекап БД

Перед --apply вызывается `systemctl start remnawave-db-backup.service`. Если бекап падает — sync прерывается.

### Обработка ошибок

- Health check: поллинг /api/system/health, 30 попыток x 10 сек
- Любой HTTP-ошибка — fail fast, прерываем весь sync
- Нет retry внутри скрипта (health check прошёл = API работает)
- Systemd Restart=on-failure, RestartSec=30s

### Логирование

- stdout: краткий прогресс (entities: N updated, N created, N deleted)
- stderr: ошибки с деталями (HTTP status, response body)

### Nix-интеграция

```nix
let
  syncScript = pkgs.writers.writePython3Bin "remnawave-sync"
    { libraries = [ pkgs.python3Packages.requests ]; }
    (builtins.readFile ./sync.py);
in {
  systemd.services.remnawave-sync = {
    description = "Sync declarative config to Remnawave API";
    after = [ "network.target" "podman-remnawave-backend.service" ];
    wants = [ "podman-remnawave-backend.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
    };
    environment = {
      REMNAWAVE_API_TOKEN = remnawave_api_token;
      REMNAWAVE_API_URL = "https://rolder.net/api";
      REMNAWAVE_CONFIGS_DIR = "${./configs}";
    };
    script = ''
      ${syncScript}/bin/remnawave-sync --apply
    '';
  };
}
```

Старые 6 сервисов удаляются полностью.

### JSON-конфиги

Формат не меняется. Путь передаётся через env REMNAWAVE_CONFIGS_DIR.

## Ограничения API

UUID при создании (POST) не принимается для nodes, hosts, users — генерируется сервером. Поэтому используем lookup по уникальному полю.
