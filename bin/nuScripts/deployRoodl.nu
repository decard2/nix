def get_projects [] {
    {
        docs: {
            bucket: "docs.rolder.app"
            icon: "📋"  # документация
        }
        playground: {
            bucket: "playground"
            icon: "🎮"  # типа игра
        }
    }
}

def ensure_project_dir [project_name: string] {
    let base_dir = ($env.HOME | path join "deployRoodl")
    let project_dir = ($base_dir | path join $project_name)

    if not ($base_dir | path exists) {
        mkdir $base_dir
    }
    if not ($project_dir | path exists) {
        mkdir $project_dir
    }
    $project_dir
}

def deployRoodl [] {
    let projects = get_projects

    # Используем иконки из конфига
    let choices = ($projects
        | transpose name info
        | each { |row| {
            display: $"($row.info.icon) ($row.name) 🪣 ($row.info.bucket)"
            value: $row.name
        }}
    )

    let selected = ($choices | input list -d display "🚀 Выбери проект для деплоя")

    if ($selected | is-empty) {
        echo "❌ Братан, надо выбрать проект!"
        return
    }

    let project = ($projects | get $selected.value)
    let deploy_dir = (ensure_project_dir $selected.value)

    print $"\n📁 Папка для деплоя: ($deploy_dir)"

    # Цикл ожидания файлов
    loop {
        print "\nЗакинь файлы и жмакни Enter для проверки (Ctrl+C для отмены)"
        let _ = (input)

        # Проверяем наличие index.html
        let index_exists = ($deploy_dir | path join "index.html" | path exists)
        if not $index_exists {
            print "\n❌ index.html не найден! Попробуем ещё раз?"
            continue
        }

        let files_count = (do -i { ^find $deploy_dir -type f | lines | length })
        print $"\n📦 Нашёл ($files_count) файлов, включая index.html"

        cd $deploy_dir
        print $"\n🚀 Погнали загружать ($files_count) файлов в ($project.bucket)...\n"

        ^aws s3 cp . $"s3://($project.bucket)" --recursive
        let exit_code = $env.LAST_EXIT_CODE

        if $exit_code == 0 {
            print "\n✅ Загрузка завершена! 🎉"

            # Очищаем папку
            cd ..
            rm -rf $deploy_dir
            mkdir $deploy_dir
            print "\n🧹 Папка для деплоя очищена\n"
            break
        } else {
            print "\n❌ Что-то пошло не так! Попробуем ещё раз?\n"
            continue
        }
    }
}
