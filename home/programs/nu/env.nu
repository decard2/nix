# Базовая конфигурация
$env.config = {
    show_banner: false
    hooks: {
        env_change: {
            PWD: [{ |before, after|
                if $before == $after { return }

                let is_activating = ($env | get -i FLOX_ACTIVATING | default false)

                if not $is_activating {
                    load-env { FLOX_ACTIVATING: true }

                    let after_has_flox = ($after | path join ".flox" | path exists)
                    let active_env = (^flox envs --active --json | from json)
                    let has_active_env = ($active_env | length) > 0

                    if $after_has_flox and (not $has_active_env) {
                        print $"\n🚀 Активация flox окружения...\n"
                        flox activate -- nu
                    }

                    hide-env FLOX_ACTIVATING
                }
            }]
        }
    }
}

# Настройка автодополнения
$env.PATH = ($env.PATH | split row (char esep) | prepend "/home/decard/.config/carapace/bin")

# Настройка автодополнения через carapace
let carapace_completer = {|spans|
  let expanded_alias = (scope aliases | where name == $spans.0 | get -i 0 | get -i expansion)

  let spans = (if $expanded_alias != null  {
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else {
    $spans
  })

  carapace $spans.0 nushell ...$spans
  | from json
}

# Применяем настройки автодополнения
mut current = (($env | default {} config).config | default {} completions)
$current.completions = ($current.completions | default {} external)
$current.completions.external = ($current.completions.external
| default true enable
| default $carapace_completer completer)

$env.config = $current

# Функции для работы с переменными окружения
# def --env get-env [name] { $env | get $name }
# def --env set-env [name, value] { load-env { $name: $value } }
# def --env unset-env [name] { hide-env $name }

# Определяем правильный запуск bash
def --env bash [] {
  ^/run/current-system/sw/bin/bash -l
}

# Основные переменные окружения
$env.EDITOR = 'zeditor'
$env.VISUAL = 'zeditor'
$env.TERM = 'xterm-color'

# Настройки Wayland
$env.XDG_SESSION_TYPE = 'wayland'
$env.XDG_CURRENT_DESKTOP = 'Hyprland'
$env.XDG_SESSION_DESKTOP = 'Hyprland'

# Загружаем кастомные скрипты
source /home/decard/nix/bin/nuScripts/deployRoodl.nu

# Автозапуск Hyprland
def check_and_start_hyprland [] {
  let display = ($env | get -i DISPLAY | default "")
  let wayland_display = ($env | get -i WAYLAND_DISPLAY | default "")

  if ($display == "") and ($wayland_display == "") {
    try {
      if (uwsm check may-start | complete).exit_code == 0 {
        exec uwsm start hyprland-uwsm.desktop
        exit
      }
    } catch {
      null
    }
  }
}

check_and_start_hyprland
