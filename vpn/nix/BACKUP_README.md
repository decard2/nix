# Remnawave Panel Backup System

## Как пользоваться

### Команды

```bash
# Создать бекап вручную
sudo systemctl start remnawave-db-backup.service

# Посмотреть доступные бекапы
remnawave-list-backups

# Восстановить из последнего бекапа
sudo remnawave-restore latest

# Восстановить из конкретного файла
sudo remnawave-restore /opt/remnawave/backups/remnawave_20251005_081447.dump

# Синхронизировать с облаком вручную
remnawave-sync-yandex
```

### Расписание

- **Бекапы**: каждый день в 01:00 МСК
- **Синхронизация**: автоматически при создании бекапа
- **Очистка**: локально >30 дней, в облаке >180 дней

### Файлы

- Бекапы: `/opt/remnawave/backups/`
- Облако: `rolder-backups/rolder-net/`

## Как это устроено

### Компоненты

1. **backup.nix** - создание бекапов PostgreSQL
2. **restore.nix** - команды восстановления
3. **yandex-backup.nix** - синхронизация с Yandex Object Storage

### Автоматика

- `remnawave-db-backup.timer` - ежедневный таймер бекапов
- `remnawave-yandex-backup-sync.path` - отслеживает изменения в папке бекапов
- При новом бекапе автоматически запускается `remnawave-yandex-backup-sync.service`

### Технические детали

- Формат бекапов: PostgreSQL custom format (.dump)
- Сжатие: уровень 9
- Транспорт: rclone с S3-совместимым API
- Мониторинг: systemd path units + inotify
