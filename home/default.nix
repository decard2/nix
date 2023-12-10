{ inputs, config, pkgs, ... }:
{
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./shell.nix
    ./de.nix
    ./hyprland.nix
    ./dev.nix
    ./apps    
  ];

  home.username = "decard";
  home.homeDirectory = "/home/decard";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
