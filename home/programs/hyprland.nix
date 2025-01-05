{ pkgs, ... }: {
  home.packages = with pkgs; [
    playerctl
    wireplumber
    brightnessctl
    hyprshot
    wl-clipboard
    hyprcursor
    hyprsunset
    hyprpolkitagent
  ];

  wayland.windowManager.hyprland = {
    systemd.enable = false;
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

      # 3. Настройки поведения окон
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        split_width_multiplier = 1.0;
        force_split = 2;
        special_scale_factor = 0.95;
      };

      # 4. Настройки ввода
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:win_space_toggle,grp_led:scroll";
        numlock_by_default = true;
      };

      # 5. Правила для окон
      windowrule = [ ];

      # 6. Автозапуск
      exec-once = [
        "uwsm app -- hyprcursor"
        "[workspace special:term silent] uwsm app -- kitty"
        "[workspace special:btop silent] uwsm app -- kitty -e btop"
        "[workspace special:telegram silent] uwsm app -- telegram-desktop"
        "uwsm app -- udiskie"
        "uwsm app -- ~/nix/bin/auto_hyprsunset.nu"
        # "uwsm app -- sudo awg-quick up ~/nix/config/vpn.conf"
        # "[workspace special:jora silent] uwsm app -- kitty -e jora"
        "[workspace special:jora silent] uwsm app -- kitty"
      ];

      # 7. Бинды клавиш и мыши
      bindm =
        [ "SUPER, mouse:272, movewindow" "SUPER, mouse:273, resizewindow" ];

      bind = [
        # Основные команды
        "SUPER, D, exec, uwsm app -- yofi"
        "SUPER, Return, exec, uwsm app -- kitty"
        "SUPER, Q, killactive,"
        "SUPER, M, exit,"
        "SUPER, V, togglefloating,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit,"
        "SUPER, Z, togglespecialworkspace, jora"

        # VPN
        # "SUPER, W, exec, uwsm app -- sudo awg-quick up ~/nix/config/vpn.conf"
        # "SUPER, E, exec, uwsm app -- sudo awg-quick down ~/nix/config/vpn.conf"
        # Tailscale exit node
        "SUPER, W, exec, uwsm app -- sudo tailscale up --login-server=https://hs.rolder.net --exit-node=moscow"
        "SUPER, E, exec, uwsm app -- sudo tailscale up --login-server=https://hs.rolder.net --exit-node="

        # Виртуалка
        "SUPER_SHIFT, W, exec, uwsm app -- virsh -c qemu:///system start win11; uwsm app -- virt-viewer --connect qemu:///system win11"
        "SUPER_SHIFT, E, exec, uwsm app -- virsh -c qemu:///system shutdown win11"

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
        ", Print, exec, uwsm app -- hyprshot -m region --clipboard-only"

        # Медиа клавиши
        ", XF86AudioPlay, exec, uwsm app -- playerctl play-pause"
        ", XF86AudioNext, exec, uwsm app -- playerctl next"
        ", XF86AudioPrev, exec, uwsm app -- playerctl previous"
        ", XF86AudioStop, exec, uwsm app -- playerctl stop"

        # Звук
        ", XF86AudioRaiseVolume, exec, uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, uwsm app -- wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, uwsm app -- wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, uwsm app -- wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Яркость
        ", XF86MonBrightnessUp, exec, uwsm app -- brightnessctl set 1%+"
        ", XF86MonBrightnessDown, exec, uwsm app -- brightnessctl set 1%-"
      ];
    };
  };
}
