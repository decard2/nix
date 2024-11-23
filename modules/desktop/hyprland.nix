{ config, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Явно указываем пакеты из флейка
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    enableNvidiaPatches = true;
  };

  # Основные тулзы для Hyprland
  environment.systemPackages = with pkgs; [
    waybar
    wofi
    dunst

    grim
    slurp
    wl-clipboard
    brightnessctl
  ];

  # Включаем основные сервисы
  services = {
    dbus.enable = true;
    udisks2.enable = true;
    power-profiles-daemon.enable = true;
  };
}
