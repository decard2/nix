{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libxkbcommon
    xorg.xkeyboardconfig
    lsof
    intel-vaapi-driver
    intel-media-driver
    vpl-gpu-rt
    mesa
  ];
}
