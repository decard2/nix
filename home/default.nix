{ config, pkgs, ... }:

{
  imports = [
    ./programs
    ./packages.nix
    ./fonts.nix
  ];

  home = {
    username = "decard";
    homeDirectory = "/home/decard";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
}
