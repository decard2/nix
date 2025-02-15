#!/usr/bin/env fish

function cleanup --on-signal SIGINT
    echo -e "\n👋 Ладно, братан, в другой раз!"
    exit 1
end

# Функция для получения проектов
function get_projects
    echo '{
        "docs": {
            "bucket": "docs.rolder.app",
            "icon": "📋"
        },
        "playground": {
            "bucket": "playground",
            "icon": "🎮"
        }
    }' | jq .
end

# Создание директории проекта
function ensure_project_dir -a project_name
    set base_dir "$HOME/deployRoodl"
    set project_dir "$base_dir/$project_name"

    if not test -d "$base_dir"
        mkdir -p "$base_dir"
    end
    if not test -d "$project_dir"
        mkdir -p "$project_dir"
    end
    echo "$project_dir"
end

function deployRoodl
    # Получаем проекты и формируем список для выбора
    set projects (get_projects)
    set choices (echo $projects | jq -r 'to_entries | .[] | .value.icon + " " + .key + " 🪣 " + .value.bucket')

    # Используем fzf для выбора
    set selected (printf '%s\n' $choices | fzf --prompt="🚀 Выбери проект для деплоя: ")

    # Проверяем прерывание на этапе выбора
    if test $status -eq 130
        return 1
    end

    if test -z "$selected"
        echo "❌ Братан, надо выбрать проект!"
        return 1
    end

    # Парсим выбранное значение
    set project_name (echo $selected | awk '{print $2}')
    set bucket (echo $projects | jq -r ".[\"$project_name\"].bucket")

    # Создаём директорию для деплоя
    set deploy_dir (ensure_project_dir $project_name)
    echo -e "\n📁 Папка для деплоя: $deploy_dir"

    # Основной цикл
    while true
        echo -e "\nЗакинь файлы и жмакни Enter для проверки (Ctrl+C для отмены)"
        read input

        # Проверяем прерывание на этапе ожидания файлов
        if test $status -eq 1
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

        if test $aws_status -eq 130
            echo -e "\n❌ Загрузка прервана!"
            return 1
        end

        if test $aws_status -eq 0
            echo -e "\n✅ Загрузка завершена! 🎉"

            # Очищаем папку
            cd ..
            rm -rf $deploy_dir
            mkdir -p $deploy_dir

            if test $status -ne 0
                echo -e "\n❌ Ошибка при очистке папки!"
                return 1
            end

            echo -e "\n🧹 Папка для деплоя очищена\n"
            break
        else
            echo -e "\n❌ Что-то пошло не так! Попробуем ещё раз?\n"
            continue
        end
    end
end

# Запускаем функцию
deployRoodl
