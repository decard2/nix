#!/usr/bin/env fish

# Жора - скрипт резервного копирования с минимальным выводом
# Версия: 4.0

# ===== НАСТРОЙКИ =====
# Папки для копирования
set -l SOURCE_DIRS \
    "$HOME/nix" \
    "$HOME/.kube" \
    "$HOME/.mozilla" \
    "$HOME/.config" \
    "$HOME/.ssh" \
    "$HOME/projects"

# Директория для резервных копий
set -l BACKUP_DIR "/run/media/decard/955445b6-b2e9-41a1-9094-ba15f2489a3a"

# Имя директории с датой и временем
set -l BACKUP_NAME "backup_"(date +%Y-%m-%d_%H-%M)
set -l BACKUP_PATH "$BACKUP_DIR/$BACKUP_NAME"

# Шаблоны для исключения файлов
set -l EXCLUDE_PATTERNS \
    "node_modules" \
    ".git" \
    "*.log" \
    "*.tmp" \
    "*.temp" \
    ".DS_Store" \
    "*.swp" \
    "__pycache__" \
    "target" \
    "dist" \
    "build"

# Время начала для расчета длительности
set -l START_TIME (date +%s)

# Проверяем наличие rsync
if not command -q rsync
    echo "ОШИБКА: rsync не установлен. Установите его для работы скрипта."
    exit 1
end

# Создаем директорию для резервной копии
mkdir -p $BACKUP_PATH
if test $status -ne 0
    echo "ОШИБКА: не удалось создать директорию $BACKUP_PATH"
    exit 1
end

# ===== ЗАГОЛОВОК =====
echo "=== ЖОРА: РЕЗЕРВНОЕ КОПИРОВАНИЕ ==="
echo "Начало: "(date +%H:%M:%S)
echo "Директория бэкапа: $BACKUP_PATH"
echo

# Выводим список директорий для копирования
echo "Директории для копирования:"
for dir in $SOURCE_DIRS
    echo "  - "(basename $dir)
end
echo

# ===== КОПИРОВАНИЕ =====
set -l success_count 0
set -l error_count 0
set -l skipped_count 0

for source_dir in $SOURCE_DIRS
    set -l dir_name (basename $source_dir)

    # Проверяем существование директории
    if not test -d $source_dir
        echo "⚠️ ПРОПУСК: $dir_name (директория не найдена)"
        set skipped_count (math $skipped_count + 1)
        continue
    end

    # Размер исходной директории
    set -l src_size (du -sh $source_dir | cut -f1)
    echo "📁 Копирование: $dir_name ($src_size)"

    # Собираем параметры исключения
    set -l exclude_args
    for pattern in $EXCLUDE_PATTERNS
        set exclude_args $exclude_args "--exclude=$pattern"
    end

    # Создаем директорию назначения
    mkdir -p "$BACKUP_PATH/$dir_name"

    echo "  ⏳ Копирование в процессе..."

    # Копируем с проверкой
    # -r обязательно для рекурсивного копирования
    # -l для копирования символических ссылок как ссылок
    # -p сохраняет права доступа
    # -t сохраняет время модификации
    # -q для тихого режима
    rsync -rlpt -q $exclude_args "$source_dir/" "$BACKUP_PATH/$dir_name/"

    if test $status -eq 0
        # Проверяем, что файлы действительно скопировались
        set -l file_count (find "$BACKUP_PATH/$dir_name" -type f | wc -l)
        if test $file_count -gt 0
            set -l dest_size (du -sh "$BACKUP_PATH/$dir_name" | cut -f1)
            echo "  ✅ Готово: $dir_name ($dest_size)"
            set success_count (math $success_count + 1)
        else
            echo "  ❌ Ошибка: директория пуста после копирования"
            set error_count (math $error_count + 1)
        end
    else
        echo "  ❌ Ошибка: не удалось скопировать $dir_name"
        set error_count (math $error_count + 1)
    end
end

# ===== СТАТИСТИКА =====
# Рассчитываем различные параметры
set -l end_time (date +%s)
set -l duration (math $end_time - $START_TIME)
set -l minutes (math "floor($duration / 60)")
set -l seconds (math "$duration % 60")
set -l total_size (du -sh $BACKUP_PATH | cut -f1)
set -l files_count (find $BACKUP_PATH -type f | wc -l)
set -l dirs_count (find $BACKUP_PATH -type d | wc -l)

# Выводим результаты
echo
echo "=== ЖОРА: РЕЗЕРВНОЕ КОПИРОВАНИЕ ЗАВЕРШЕНО ==="
echo "📊 Результаты:"
echo "  • Успешно скопировано: $success_count директорий"
if test $error_count -gt 0
    echo "  • С ошибками: $error_count директорий"
end
if test $skipped_count -gt 0
    echo "  • Пропущено: $skipped_count директорий"
end
echo "  • Файлов скопировано: $files_count"
echo "  • Директорий создано: $dirs_count"
echo "  • Размер резервной копии: $total_size"
echo "  • Время выполнения: $minutes мин $seconds сек"
echo "  • Время окончания: "(date +%H:%M:%S)
echo "  • Расположение: $BACKUP_PATH"
echo
echo "✨ Жора сделал резервное копирование на отлично! ✨"
