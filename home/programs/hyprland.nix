{pkgs, ...}: {
  home.packages = with pkgs; [
    playerctl
    wireplumber
    brightnessctl
    wlsunset
    hyprshot
    wl-clipboard
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # 1. Мониторы и воркспейсы
      monitor = [
        "DP-1,1920x1080@60.0,1500x0,1.0"
        "eDP-1,3000x2000@59.999001,0x0,2.0"
      ];
      workspace = [
        "1,monitor:eDP-1"
        "2,monitor:eDP-1"
        "3,monitor:DP-2"
        "4,monitor:DP-2"
        "5,monitor:DP-2"
        "6,monitor:DP-2"
        "7,monitor:DP-2"
        "8,monitor:DP-2"
        "9,monitor:DP-2"
      ];

      # 2. Основные настройки внешнего вида
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        "col.active_border" = "rgba(33ccffee)";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
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

      # 3. Настройки поведения окон
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        split_width_multiplier = 1.0;
        force_split = 1;
        special_scale_factor = 0.95;
      };

      # 4. Настройки ввода
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:win_space_toggle,grp_led:scroll";
        numlock_by_default = true;
      };

      # 5. Правила для окон
      windowrule = [
      ];

      # 6. Автозапуск
      exec-once = [
        "[workspace special:term silent] kitty --class btop-scratch"
        "[workspace special:btop silent] kitty -e btop"
        "[workspace special:telegram silent] telegram-desktop"
        "udiskie &"
        "wlsunset -l 52.3 -L 104.3 -t 4500 -T 6500"
      ];

      # 7. Бинды клавиш и мыши
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      bind = [
        # Основные команды
        "SUPER, D, exec, yofi"
        "SUPER, Return, exec, kitty"
        "SUPER, Q, killactive,"
        "SUPER, M, exit,"
        "SUPER, E, exec, dolphin"
        "SUPER, V, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit,"

        # VPN
        "SUPER_SHIFT, W, exec, nmcli connection up vpn"
        "SUPER_SHIFT, E, exec, nmcli connection down vpn"

        # Скретчпады
        "CTRL, grave, togglespecialworkspace, term"
        "SUPER, grave, togglespecialworkspace, btop"
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

        # Воркспейсы
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

        # Дополнительные хоткеи
        "SUPER, tab, workspace, previous"
        "SUPER, F, fullscreen, 0"
        "SUPER_SHIFT, F, fullscreen, 1"
        ", Print, exec, hyprshot -m region --clipboard-only"

        # Медиа клавиши
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"

        # Звук
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Яркость
        ", XF86MonBrightnessUp, exec, brightnessctl set 1%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 1%-"
      ];
    };
  };
}
