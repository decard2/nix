{ pkgs, flox, ... }:
{
  home.packages = with pkgs; [
    unzip
    btop
    neofetch
    vim
    udiskie
    pamixer
    pavucontrol
    nvd
    zettlr
    bun
    gitui
    flox.packages.${pkgs.system}.default
  ];
}
