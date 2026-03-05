# Remnawave: анализ декларативной синхронизации

## Цель

Все иметь декларативно (nodes, hosts, users, squads, profiles), а в панели смотреть только статистику.

## Текущая архитектура

### Декларативный источник (JSON)

- `configs/nodes.json` — ноды (2 шт)
- `configs/hosts.json` — хосты для подписок
- `configs/users.json` — пользователи (8 шт)
- `configs/internal-squads.json` — группы доступа
- `configs/config-profiles.json` — профили конфигурации
- `configs/additional-settings.json` — настройки подписок

### Синхронизация

6 отдельных systemd oneshot-сервисов (`sync.nix`), каждый:

1. Ждет API (до 5 минут polling, 30 попыток x 10 сек)
2. Получает текущее состояние из API
3. Сравнивает по UUID/имени
4. Создает или обновляет через PATCH/POST

Порядок: config-profiles -> internal-squads -> hosts/nodes (параллельно) -> users -> additional-settings

## Проблемы

### 1. Хрупкий reconciliation

Сопоставление по address+port с fallback на name ненадежно. UUID генерируется панелью, а не нами — при пересоздании объектов UUID меняется, скрипт создает дубли вместо обновления.

### 2. Гонки при старте

6 oneshot-сервисов с `wantedBy = multi-user.target`, порядок через `after` но без жесткой цепочки. Если API еще не готов после 30 retry — silent failure с `RemainAfterExit = true` (systemd считает сервис "succeeded").

### 3. Нет drift detection

Если кто-то поменял что-то в панели руками, sync при следующем rebuild перетрет частично (PATCH обновляет поля, но не удаляет лишнее).

### 4. Нет идемпотентности удаления

JSON описывает желаемое состояние, но нет логики "удалить то, чего нет в JSON". Если убрал ноду из JSON — она останется в панели.

### 5. Bash в Nix

400+ строк bash внутри Nix, сложно отлаживать.

## Варианты решения

### A: Починить текущий подход (минимальные изменения)

- Добавить UUID в JSON как primary key (мы контролируем UUID, а не панель)
- Добавить удаление "лишних" объектов (desired state reconciliation)
- Объединить 6 сервисов в один с правильным порядком
- Добавить `ExecStartPre` проверку здоровья API вместо polling в каждом скрипте

### B: Один sync-скрипт на Python/Go (рекомендуется)

Вместо 6 bash-сервисов — один скрипт, который:

- Читает все JSON-файлы
- Делает полный reconcile в правильном порядке (profiles -> squads -> nodes -> hosts -> users)
- Поддерживает `--dry-run` для проверки
- Запускается как systemd сервис или вручную
- Нормальная обработка ошибок, логирование

Упаковывается в Nix (`pkgs.writers.writePython3Bin` или derivation).

### C: Работать напрямую с БД

PostgreSQL рядом — можно SQL-миграциями управлять состоянием. Но ломается при обновлении Remnawave (схема может измениться). Не рекомендуется.

### D: Terraform provider для Remnawave API

REST API уже есть — Terraform отлично решает reconciliation + state tracking + drift detection. Но overhead разработки провайдера. Overkill для текущего масштаба.

## Рекомендация

Вариант **B** — один Python-скрипт. Решает все текущие проблемы (гонки, порядок, идемпотентность, удаление) без overengineering.
