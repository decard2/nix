# NixOS Configuration

Ё-моё, какая конфигурация! Погнали разбираться.

## Структура конфига

```
.
├── flake.nix           # Главный флейк, тут вся магия начинается
├── hosts/
│   └── emerald/        # Конфиг для нашего красавца-компа
│       ├── default.nix    # Основные настройки
│       └── hardware.nix   # Железячные дела
└── modules/
    ├── desktop/        # Всё для красивого рабочего стола
    │   ├── default.nix    # Общие настройки десктопа
    │   ├── fonts.nix      # Шрифты чтоб глаза радовались
    │   └── hyprland.nix   # Hyprland - наш любимый WM
    ├── system/         # Системные настройки
    │   ├── default.nix    # Базовые штуки
    │   ├── btrfs.nix      # Настройки BTRFS и снапшотов
    │   ├── nixos-snapshots.nix # Интеграция снапшотов с NixOS
    │   └── locale.nix     # Локали и часовые пояса
    └── users/          # Настройки юзеров
        ├── default.nix    # Создание пользователя
        ├── home.nix       # Home Manager конфиг
        └── programs/      # Конфиги программ
            ├── nushell.nix   # Наш топовый шелл
            ├── starship.nix  # Красивый промпт
            └── zed.nix       # Редактор для крутых
```

## Быстрый старт

```bash
# 1. Грузимся с NixOS minimal ISO

# 2. Поднимаем вайфай (если нужно)
sudo systemctl start wpa_supplicant
# Смотрим доступные сети
iwctl station wlan0 scan
iwctl station wlan0 get-networks
# Коннектимся (замени MY_WIFI и PASSWORD на свои)
iwctl station wlan0 connect "MY_WIFI"
# Вводим пароль когда спросит

# Проверяем что поймали инет
ping -c 3 google.com

# 3. Ставим нужные тулзы
nix-shell -p nushell git wget

# 3. Качаем и запускаем скрипт установки
wget https://raw.githubusercontent.com/decard2/nix/main/install.nu
chmod +x install.nu
./install.nu
```

## Структура BTRFS

У нас используется следующая структура сабволюмов:
- `@` - корневая файловая система
- `@home` - домашние директории пользователей
- `@nix` - nixos store
- `@cache` - временные файлы и кэши
- `@log` - системные логи

Преимущества такой структуры:
- Снапшоты не включают временные файлы
- Можно отдельно управлять разными типами данных
- Оптимизированное использование места
- Легкое восстановление при проблемах

## Управление системой

### Безопасное обновление
```bash
# Обновление с автоматическими снапшотами
sudo nixos-safe-rebuild

# Или используя алиас
nsr
```

### Откат системы
```bash
# Интерактивный откат к предыдущему состоянию
sudo nixos-rollback

# Или используя алиас
nrb
```

### Управление снапшотами
```bash
# Посмотреть все снапшоты
snapper list
# или
nls

# Сравнить изменения между снапшотами
snapper diff NUMBER1..NUMBER2
# или
ndf NUMBER1..NUMBER2
```

### Обслуживание системы
```bash
# Очистить временные файлы
sudo nixos-clean-temp

# Сделать ручной снапшот
sudo nixos-snapshot pre "Описание снапшота"

# Проверить здоровье BTRFS
sudo btrfs scrub start /
```

## Полезные алиасы

В nushell настроены следующие алиасы:

### Общие
- `ll` - расширенный список файлов
- `g` - сокращение для git
- `update` - обновление системы

### Снапшоты и система
- `nsr` - безопасное обновление с созданием снапшотов
- `nrb` - откат к предыдущему состоянию
- `nls` - список всех снапшотов
- `ndf` - сравнение снапшотов

## BTRFS фишки

### Снапшоты
```bash
# Создать снапшот корневой ФС (только для чтения)
sudo btrfs subvolume snapshot -r / /.snapshots/root-$(date +%F)

# Создать снапшот домашней директории
sudo btrfs subvolume snapshot -r /home /.snapshots/home-$(date +%F)

# Посмотреть список сабволюмов
sudo btrfs subvolume list /

# Удалить старый снапшот
sudo btrfs subvolume delete /.snapshots/root-OLD
```

### Проверка и обслуживание
```bash
# Проверить использование места
sudo btrfs filesystem usage /

# Проверить состояние файловой системы
sudo btrfs scrub start /

# Проверить статус scrub
sudo btrfs scrub status /

# Включить автобалансировку
sudo btrfs balance start /
```

### Сжатие
Все разделы уже смонтированы с опцией `compress=zstd`. Чтобы пережать существующие файлы:
```bash
# Найти и пережать все файлы в директории
sudo btrfs filesystem defragment -r -v -czstd /path/to/dir
```

### Рекомендации
- Делайте регулярные снапшоты перед обновлениями
- Периодически запускайте scrub для проверки целостности
- Следите за свободным местом (минимум 10% должно быть свободно)
- Используйте автоматические снапшоты через snapper

## Лайфхаки

- Коммить почаще, братан!
- Тестируй изменения через `nixos-rebuild test`
- Держи бэкап конфига где-нибудь в облаке
- Перед большими изменениями делай бранч
- Держи копию флейка локально на случай проблем с сетью
- Проверяй syntax через `nix flake check`
- Не забывай про `git push`!

## Известные проблемы

1. Если Hyprland не стартует:
```bash
# Смотрим логи
journalctl -xe
# Проверяем статус
systemctl status display-manager
```

2. Проблемы со звуком:
```bash
# Перезапускаем PipeWire
systemctl --user restart pipewire
```

3. GDM не запускается:
```bash
# Проверяем статус
systemctl status gdm
# Смотрим логи
journalctl -u gdm
```

4. Проблемы с WiFi:
```bash
# Проверяем статус NetworkManager
systemctl status NetworkManager
# Рестартим если надо
sudo systemctl restart NetworkManager
# Смотрим доступные сети
nmcli device wifi list
```

5. Проблемы со снапшотами:
```bash
# Проверяем статус snapper
systemctl status snapper-timeline.timer
systemctl status snapper-cleanup.timer

# Смотрим логи снапшотов
journalctl -u snapper-timeline
```
