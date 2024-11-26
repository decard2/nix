{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
<<<<<<< HEAD
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
=======
    (nerdfonts.override {fonts = ["FiraCode"];})
>>>>>>> temp-branch
  ];
}
