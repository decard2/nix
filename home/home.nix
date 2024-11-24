{ config, pkgs, ... }:

{
  home.username = "decard";
  home.homeDirectory = "/home/decard";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    btop
    neofetch
    #waybar
    #wofi
    #wl-clipboard
    #brightnessctl
    #pamixer
    #grim
    #slurp
  ];

  programs.kitty = {
      enable = true;
      font = {
        name = "JetBrains Mono";
        size = 12;
      };
      settings = {
        background_opacity = "0.95";
        confirm_os_window_close = 0;
      };
      extraConfig = ''
        # Тут можно добавить любые дополнительные настройки
      '';
  };

  wayland.windowManager.hyprland = {
    enable = true;  # использует системный Hyprland
    settings = {
      monitor = [
        ",preferred,auto,1"  # это значит "для всех мониторов используй оптимальное разрешение"
      ];

      # env = [
      #   "WLR_RENDERER_ALLOW_SOFTWARE,1"
      # ];

      # exec-once = [
      #   "waybar"
      # ];

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

  home.stateVersion = "24.05";
}
