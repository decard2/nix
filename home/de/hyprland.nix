{
  wayland.windowManager.hyprland = {
    configType = "hyprlang";
    systemd.enable = true;
    systemd.variables = [ "--all" ];
    enable = true;
    # Use packages from NixOS module to avoid conflicts
    package = null;
    portalPackage = null;

    settings = {
      # Мониторы
      monitor = [
        "DP-2,1920x1080@60.0,1500x0,1.0" # Правый
        "eDP-1,3000x2000@59.999001,0x0,2.0" # Левый
      ];

      # Воркспейсы: 1-4 на правом мониторе, 5 стационарный на левом (btop)
      workspace = [
        "9,monitor:eDP-1,default:true"
        "1,monitor:DP-2,default:true"
        "2,monitor:DP-2"
        "3,monitor:DP-2"
        "4,monitor:DP-2"
        "5,monitor:DP-2"
      ];

      # Внешний вид
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgba(33ccffee)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        no_focus_fallback = false;
      };

      decoration = {
        rounding = 8;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        animation = [
          "windows, 1, 3, default"
          "border, 1, 2, default"
          "fade, 1, 4, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        split_width_multiplier = 1.0;
        force_split = 2;
        special_scale_factor = 0.975;
      };

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:win_space_toggle,grp_led:scroll";
        numlock_by_default = true;
      };

      # Автозапуск
      # ВАЖНО: uwsm-app требует `--` перед командой, иначе аргументы вида `-e`,
      # `-c`, `--flag` парсятся как опции самого `uwsm app` и daemon валится с
      # «unrecognized arguments», после чего его error-flag съедает ответы
      # следующих клиентов — в итоге не стартует половина автозапуска.
      exec-once = [
        "uwsm-app -- ~/nix/home/scripts/autoHyprsunset.fish"
        # Приложения
        "[workspace 2 silent] uwsm-app -- yandex-browser-stable"
        # btop — воркспейс 9, левый монитор (стационарный)
        "[workspace 9 silent] uwsm-app -- ghostty -e btop"
        # SUPER терминалы
        "[workspace special:s-grave silent] uwsm-app -- ghostty"
        "[workspace special:s-1 silent] uwsm-app -- ghostty"
        "[workspace special:s-2 silent] uwsm-app -- ghostty"
        "[workspace special:s-3 silent] uwsm-app -- ghostty"
        # CTRL терминалы
        "[workspace special:c-grave silent] uwsm-app -- ghostty"
        "[workspace special:c-1 silent] uwsm-app -- ghostty"
        "[workspace special:c-2 silent] uwsm-app -- ghostty"
        "[workspace special:c-3 silent] uwsm-app -- ghostty"
        # Приложения скретчпад
        # "[workspace special:decardos silent] uwsm-app -- ghostty --working-directory=/home/decard/dos -e claude"
        "[workspace special:telegram silent] uwsm-app -- Telegram"
        # Zed последним — без silent, забирает фокус на workspace 1
        "[workspace 1] uwsm-app -- zed"
      ];

      # Мышь
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      bind = [
        # Утилиты
        "SUPER, D, exec, uwsm-app -- hyprlauncher"
        "SUPER, Return, exec, uwsm-app -- ghostty"
        "SUPER, Q, killactive,"
        "SUPER, V, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit,"
        "SUPER, F, fullscreen, 0"
        "SUPER_SHIFT, F, fullscreen, 1"

        # Виртуалка
        "SUPER_SHIFT, W, exec, uwsm-app -- virsh -c qemu:///system start win11; uwsm-app -- virt-viewer --connect qemu:///system win11"
        "SUPER_SHIFT, Q, exec, uwsm-app -- virsh -c qemu:///system shutdown win11"

        # === Слой 1 — ALT — Воркспейсы (правый монитор) ===
        "ALT, grave, workspace, 9"
        "ALT, 1, workspace, 1"
        "ALT, 2, workspace, 2"
        "ALT, 3, workspace, 3"
        "ALT, 4, workspace, 4"
        "ALT, 5, workspace, 5"

        # Перемещение окон между воркспейсами
        "ALT_SHIFT, 1, movetoworkspace, 1"
        "ALT_SHIFT, 2, movetoworkspace, 2"
        "ALT_SHIFT, 3, movetoworkspace, 3"
        "ALT_SHIFT, 4, movetoworkspace, 4"

        # === Слой 2 — SUPER — Терминалы (скретчпады) ===
        "SUPER, grave, togglespecialworkspace, s-grave"
        "SUPER, 1, togglespecialworkspace, s-1"
        "SUPER, 2, togglespecialworkspace, s-2"
        "SUPER, 3, togglespecialworkspace, s-3"

        # === Слой 3 — CTRL — Терминалы (скретчпады) ===
        "CTRL, grave, togglespecialworkspace, c-grave"
        "CTRL, 1, togglespecialworkspace, c-1"
        "CTRL, 2, togglespecialworkspace, c-2"
        "CTRL, 3, togglespecialworkspace, c-3"

        # === Слой 4 — SUPER+CAPS — Claude Code DecardOS ===
        "ALT, F1, togglespecialworkspace, decardos"

        # Telegram
        "SUPER, A, togglespecialworkspace, telegram"

        # Управление фокусом
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"

        # Перемещение окон
        "SUPER_SHIFT, left, movewindow, l"
        "SUPER_SHIFT, right, movewindow, r"
        "SUPER_SHIFT, up, movewindow, u"
        "SUPER_SHIFT, down, movewindow, d"

        # Ресайз окон
        "SUPER_ALT, left, resizeactive, -20 0"
        "SUPER_ALT, right, resizeactive, 20 0"
        "SUPER_ALT, up, resizeactive, 0 -20"
        "SUPER_ALT, down, resizeactive, 0 20"

        # Скриншот
        ", Print, exec, uwsm-app -- hyprshot -m region --clipboard-only"

        # Медиа
        ", XF86AudioPlay, exec, uwsm-app -- playerctl play-pause"
        ", XF86AudioNext, exec, uwsm-app -- playerctl next"
        ", XF86AudioPrev, exec, uwsm-app -- playerctl previous"
        ", XF86AudioStop, exec, uwsm-app -- playerctl stop"

        # Звук
        ", XF86AudioRaiseVolume, exec, uwsm-app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, uwsm-app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, uwsm-app -- wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, uwsm-app -- wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Яркость
        ", XF86MonBrightnessUp, exec, uwsm-app -- brightnessctl set 1%+"
        ", XF86MonBrightnessDown, exec, uwsm-app -- brightnessctl set 1%-"
      ];
    };
  };
}
