{ config, pkgs, ... }:

{
  home.username = "decard";
  home.homeDirectory = "/home/decard";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Базовые тулзы
    btop
    neofetch

    # Для Wayland
    waybar
    wofi
    wl-clipboard

    # Утилиты
    brightnessctl
    pamixer

    # Для скриншотов
    grim
    slurp
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = "eDP-1,1920x1080@60,0x0,1";

      exec-once = [
        "waybar"
      ];

      bind = [
        "SUPER, Return, exec, kitty"
        "SUPER, Q, killactive,"
        "SUPER, M, exit,"
        "SUPER, E, exec, dolphin"
        "SUPER, V, togglefloating,"
        "SUPER, R, exec, wofi --show drun"
        "SUPER, P, pseudo,"
        "SUPER, J, togglesplit,"
      ];
    };
  };
}
