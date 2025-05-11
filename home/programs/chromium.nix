{ pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium.override {
      enableWideVine = true; # Для поддержки DRM контента
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    };
  };
}
