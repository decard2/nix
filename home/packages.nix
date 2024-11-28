{pkgs, ...}: {
  home.packages = with pkgs; [
    unzip
    btop
    neofetch
    vim
    udiskie
    pamixer
    pavucontrol
    nvd
  ];
}
