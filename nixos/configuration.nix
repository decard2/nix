{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
  };
  boot.initrd.availableKernelModules = [ "virtio_gpu" "virtio_pci" ];

  networking = {
      hostName = "emerald";
      networkmanager.enable = true;
      # Отключаем стандартный фаерволл для WireGuard, иначе могут быть проблемы
      firewall.checkReversePath = false;
  };

  time.timeZone = "Asia/Irkutsk";
  #i18n.defaultLocale = "ru_RU.UTF-8";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  virtualisation.libvirtd.enable = true;
  services.qemuGuest.enable = true;  # Включает QEMU guest tools
  services.spice-vdagentd.enable = true;  # Включает SPICE agent
  systemd.services.spice-vdagentd.enable = true;
  systemd.services.qemu-guest-agent.enable = true;

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
    shell = pkgs.nushell;
  };

  environment.systemPackages = with pkgs; [
    git
    vulkan-tools
    vulkan-validation-layers
    mesa
    spice-vdagent
    spice-protocol
    wireguard-tools
  ];

  programs.hyprland.enable = true;
  security.polkit.enable = true;

  system.stateVersion = "24.05";
}
