{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libxkbcommon
    xorg.xkeyboardconfig
    lsof
    vaapiIntel
    intel-media-driver
    vpl-gpu-rt
    mesa
  ];
}
