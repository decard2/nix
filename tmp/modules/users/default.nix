{ config, pkgs, ... }:

{
  imports = [
    ./home.nix
    ./programs/zed.nix
    ./programs/nushell.nix
  ];

  users.users.decard = {
    isNormalUser = true;
    description = "Decard";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
      "btrfs"
      "snapshot"
    ];

    packages = with pkgs; [
      htop
      neofetch
      bat
      eza
      ripgrep
      fd
      snapper
    ];
  };

  home-manager.users.decard.home.stateVersion = "24.05";
}
