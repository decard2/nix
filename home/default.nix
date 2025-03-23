{ pkgs, ... }:
{
  imports = [
    ./environment.nix
    ./de
    ./shell
    ./programs
    ./dev
    ./devops
  ];

  home = {
    username = "decard";
    homeDirectory = "/home/decard";
    stateVersion = "24.11";
  };

  programs = {
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    unzip
    btop
    neofetch
    nvd
  ];
}
