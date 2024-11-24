{ config, pkgs, inputs, ... }:

{
  imports = [ ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
  };

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Irkutsk";
  i18n.defaultLocale = "ru_RU.UTF-8";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
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

  programs.hyprland.enable = true;  # теперь берём из nixpkgs

  security.polkit.enable = true;

  system.stateVersion = "24.05";
}
