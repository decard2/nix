{ config, pkgs, inputs, ... }:

{
  imports = [ ];

  # Базовые настройки загрузчика
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Добавляем базовые модули для загрузки
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
  };

  # Остальная часть конфигурации без изменений
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Irkutsk";
  i18n.defaultLocale = "ru_RU.UTF-8";

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.decard = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
  };

  environment.systemPackages = with pkgs; [
    git
    kitty
  ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  security.polkit.enable = true;

  system.stateVersion = "24.05";
}
