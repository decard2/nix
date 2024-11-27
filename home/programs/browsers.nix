{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--enable-features=VaapiVideoDecodeLinuxGL"
      "--enable-zero-copy"
      "--force-dark-mode"
      "--ozone-platform=wayland"
      "--enable-features=UseOzonePlatform"
      "--enable-features=WebRTCPipeWireCapturer"
      "--enable-features=Vulkan"
      "--use-vulkan"
      "--enable-gpu-rasterization"
    ];
    package = pkgs.chromium.override {
      enableWideVine = true; # Для поддержки DRM контента
    };
  };

  home.packages = with pkgs; [
    firefox
  ];
}
