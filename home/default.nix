{ config, pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in
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
