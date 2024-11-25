{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [
        ",preferred,auto,1"
      ];

      bind = [
        "SUPER, D, exec, tofi-drun --drun-launch=true"
        "SUPER, Return, exec, kitty"
        "SUPER, Q, killactive,"
        "SUPER, M, exit,"
        "SUPER, E, exec, dolphin"
        "SUPER, V, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit,"
        "SUPER_SHIFT, W, exec, nmcli connection up work-wireguard"    # Включить VPN
        "SUPER_SHIFT, E, exec, nmcli connection down work-wireguard"  # Выключить VPN
        # Бинды для скрэтчпадов
        "CTRL, grave, togglespecialworkspace, term"     # CTRL + ~ для обычного терминала
        "SUPER, grave, togglespecialworkspace, btop"    # SUPER + ~ для btop
        "SUPER, A, togglespecialworkspace, telegram"

        # Управление фокусом окон (стрелками)
        "SUPER, left, movefocus, l"      # фокус влево
        "SUPER, right, movefocus, r"     # фокус вправо
        "SUPER, up, movefocus, u"        # фокус вверх
        "SUPER, down, movefocus, d"      # фокус вниз

        # Перемещение окон (стрелками)
        "SUPER_SHIFT, left, movewindow, l"   # двигать окно влево
        "SUPER_SHIFT, right, movewindow, r"  # двигать окно вправо
        "SUPER_SHIFT, up, movewindow, u"     # двигать окно вверх
        "SUPER_SHIFT, down, movewindow, d"   # двигать окно вниз

        # Ресайз окон (тоже стрелками)
        "SUPER_ALT, left, resizeactive, -20 0"    # уменьшить ширину
        "SUPER_ALT, right, resizeactive, 20 0"    # увеличить ширину
        "SUPER_ALT, up, resizeactive, 0 -20"      # уменьшить высоту
        "SUPER_ALT, down, resizeactive, 0 20"     # увеличить высоту

        # Управление воркспейсами
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        # Перемещение окон между воркспейсами
        "SUPER_SHIFT, 1, movetoworkspace, 1"
        "SUPER_SHIFT, 2, movetoworkspace, 2"
        "SUPER_SHIFT, 3, movetoworkspace, 3"
        "SUPER_SHIFT, 4, movetoworkspace, 4"
        "SUPER_SHIFT, 5, movetoworkspace, 5"
        "SUPER_SHIFT, 6, movetoworkspace, 6"
        "SUPER_SHIFT, 7, movetoworkspace, 7"
        "SUPER_SHIFT, 8, movetoworkspace, 8"
        "SUPER_SHIFT, 9, movetoworkspace, 9"

        # Переключение между последними воркспейсами
        "SUPER, tab, workspace, previous"

        # Режим фуллскрин
        "SUPER, F, fullscreen, 0"        # нормальный фуллскрин
        "SUPER_SHIFT, F, fullscreen, 1"  # фуллскрин без границ

        # Управление плавающими окнами
        "SUPER, Space, togglefloating"   # плавающий режим
        "SUPER, C, centerwindow"         # центрировать окно
      ];

      # Запускаем два терминала при старте
      exec-once = [
        "[workspace special:term silent] kitty --class terminal-scratch"
        "[workspace special:btop silent] kitty --class btop-scratch -e btop"
        "[workspace special:telegram silent] telegram-desktop --class telegram-scratch"
      ];

      windowrule = [
        # Правила для обычного терминала
        "float,^(terminal-scratch)$"
        "size 95% 95%,^(terminal-scratch)$"
        "center,^(terminal-scratch)$"
        "workspace special:term,^(terminal-scratch)$"

        # Правила для btop
        "float,^(btop-scratch)$"
        "size 95% 95%,^(btop-scratch)$"
        "center,^(btop-scratch)$"
        "workspace special:btop,^(btop-scratch)$"

        # Правила для телеграма
        "float,^(telegram-scratch)$"
        "size 95% 95%,^(telegram-scratch)$"
        "center,^(telegram-scratch)$"
        "workspace special:telegram,^(telegram-scratch)$"
      ];

      # Добавим немного правил для мыши
      bindm = [
        "SUPER, mouse:272, movewindow"   # двигать окна через SUPER + ЛКМ
        "SUPER, mouse:273, resizewindow" # ресайз окон через SUPER + ПКМ
      ];

      # Основные настройки
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgba(33ccffee)";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "dwindle";    # Дефолтный лейаут
      };

      # Закругления и тени
      decoration = {
        rounding = 8;

        blur = {
          enabled = false;
        };

        shadow = {
          enabled = false;
        };
      };

      # Анимации
      animations = {
        enabled = true;

        animation = [
        "windows, 1, 3, default"        # Быстрая анимация для окон
        "border, 1, 2, default"         # Быстрая анимация для бордюров
        "fade, 1, 4, default"           # Стандартное затухание
        "workspaces, 1, 4, default"     # Стандартная анимация воркспейсов
        ];
      };

      # Настройка поведения окон
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        split_width_multiplier = 1.0;
        # Новые окна будут открываться снизу
        force_split = 2;    # 1 - слева/справа, 2 - сверху/снизу
      };
    };
  };
}
