{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--enable-features=VaapiVideoDecodeLinuxGL"
      "--enable-zero-copy"
      "--force-dark-mode"
    ];
    package = pkgs.chromium.override {
      enableWideVine = true; # Для поддержки DRM контента
    };
  };

  home.packages = with pkgs; [
    firefox
  ];
}
