{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # DE
    tofi

    # Утилиты
    btop
    neofetch

    # Разработка
    zed-editor
    rust-analyzer
    nodePackages.typescript-language-server
    nodePackages.typescript

    # Шрифты
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
