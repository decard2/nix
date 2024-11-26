{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];
}
