{ config, pkgs, ... }:
{  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "lemerald"; # Define your hostname.
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Irkutsk";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=300
  '';  
  users.users.decard = {
    isNormalUser = true;
    description = "Decard";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };  
}
