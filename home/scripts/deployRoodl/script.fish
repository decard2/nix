#!/usr/bin/env fish

function cleanup --on-signal SIGINT
    echo -e "\n👋 Ладно, братан, в другой раз!"
    exit 1
end

# Определяем путь к конфигу - используем ту же директорию, что и скрипт
set base_dir (dirname (status --current-filename))
set config_path "$base_dir/projects.json"

echo "🔍 Ищу конфиг: $config_path"

# Функция для получения проектов из конфига
function get_projects
    # Проверяем существование файла конфига
    if not test -f "$config_path"
        echo "❌ Файл конфига не найден: $config_path"
        return 1
    end

    # Читаем файл конфига
    cat "$config_path"
end

# Создание директории проекта
function ensure_project_dir -a project_name
    set deploy_dir "$HOME/deployRoodl/$project_name"
    mkdir -p "$deploy_dir"
    echo "$deploy_dir"
end

function deployRoodl
    # Получаем проекты
    set projects_json (get_projects)

    if test $status -ne 0
        echo "❌ Не удалось прочитать конфиг!"
        return 1
    end

    # Проверяем, что файл валидный JSON
    echo "$projects_json" | jq . > /dev/null 2>&1

    if test $status -ne 0
        echo "❌ Файл конфига содержит невалидный JSON!"
        return 1
    end

    # Формируем список для выбора
    set choices (echo "$projects_json" | jq -r 'to_entries | .[] | .value.icon + " " + .key + " 🪣 " + .value.bucket')

    if test -z "$choices"
        echo "❌ Не удалось получить список проектов из конфига!"
        return 1
    end

    # Выводим для отладки
    echo "📋 Доступные проекты:"
    printf "%s\n" $choices

    # Используем fzf для выбора
    set selected (printf '%s\n' $choices | fzf --prompt="🚀 Выбери проект для деплоя: ")

    # Проверяем прерывание
    if test $status -ne 0
        echo "👋 Операция отменена!"
        return 1
    end

    if test -z "$selected"
        echo "❌ Братан, надо выбрать проект!"
        return 1
    end

    # Парсим выбранное значение
    set project_name (echo $selected | awk '{print $2}')
    set bucket (echo "$projects_json" | jq -r ".[\"$project_name\"].bucket")

    # Создаём директорию для деплоя
    set deploy_dir (ensure_project_dir $project_name)
    echo -e "\n📁 Папка для деплоя: $deploy_dir"

    # Основной цикл
    while true
        echo -e "\nЗакинь файлы и жмакни Enter для проверки (Ctrl+C для отмены)"
        read -l input

        # Проверяем прерывание на этапе ожидания файлов
        if test $status -ne 0
            echo "👋 Операция отменена!"
            return 1
        end

        # Проверяем index.html
        if not test -f "$deploy_dir/index.html"
            echo -e "\n❌ index.html не найден! Попробуем ещё раз?"
            continue
        end

        set files_count (find $deploy_dir -type f | wc -l)
        echo -e "\n📦 Нашёл $files_count файлов, включая index.html"

        cd $deploy_dir
        echo -e "\n🚀 Погнали загружать $files_count файлов в $bucket...\n"

        # Загрузка в S3 с обработкой прерывания
        aws s3 cp . "s3://$bucket" --recursive
        set aws_status $status

        if test $aws_status -ne 0
            echo -e "\n❌ Что-то пошло не так при загрузке!"
            continue
        else
            echo -e "\n✅ Загрузка завершена! 🎉"

            # Очищаем папку
            cd ..
            rm -rf $deploy_dir
            mkdir -p $deploy_dir

            echo -e "\n🧹 Папка для деплоя очищена\n"
            break
        end
    end
end

# Запускаем функцию
deployRoodl
