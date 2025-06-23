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
    stateVersion = "25.05";
  };

  programs = {
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    unzip
    btop
    neofetch
    nvd
    sshpass
  ];
}
