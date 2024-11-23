{ config, pkgs, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Базовые настройки загрузчика
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Сеть
  networking.networkmanager.enable = true;

  # Локаль и время
  time.timeZone = "Asia/Irkutsk";
  i18n.defaultLocale = "ru_RU.UTF-8";

  # Иксы и вайланд
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  # Звук
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Юзер
  users.users.decard = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
  };

  # Базовые пакеты
  environment.systemPackages = with pkgs; [
    git
    kitty
  ];

  # Включаем Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Нужно для Хайпрленда
  security.polkit.enable = true;

  # Не забываем про это
  system.stateVersion = "24.05";
}
