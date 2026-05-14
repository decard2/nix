{ pkgs, ... }:
{
  home.packages = with pkgs; [
    hyprlauncher
    papirus-icon-theme
  ];
}
