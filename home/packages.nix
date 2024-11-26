{pkgs, ...}: {
  home.packages = with pkgs; [
    unzip
    btop
    neofetch
    vim
    firefox
  ];
}
