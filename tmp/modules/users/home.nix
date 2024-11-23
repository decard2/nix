{ config, pkgs, ... }:

{
  home-manager.users.decard = { pkgs, ... }: {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      systemd.variables = ["--all"]; # Для корректной работы systemd

      settings = {
        "$mod" = "SUPER";

        # Базовые бинды
        bind = [
          "$mod, Return, exec, kitty"
          "$mod, Q, killactive"
          "$mod, M, exit"
          "$mod, E, exec, dolphin"
          "$mod, V, togglefloating"
          "$mod, R, exec, wofi --show drun"
          "$mod, P, pseudo"
          "$mod, J, togglesplit"

          # Скриншоты
          ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        ];

        # Настройки монитора (замени на свои)
        monitor = [
          "DP-1,1920x1080@144,0x0,1"
        ];
      };
    };

    # Включаем темы для GTK
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome.adwaita-icon-theme;
      };
    };

    home.stateVersion = "24.05";
  };
}
