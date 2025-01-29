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
    gitui
    flox.packages.${pkgs.system}.default
    jq
    fzf
    dnsutils
    xfce.thunar
  ];
}
