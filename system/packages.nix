{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libxkbcommon
    xkeyboardconfig
    lsof
    intel-vaapi-driver
    intel-media-driver
    vpl-gpu-rt
    mesa
    bluetuith
  ];
}
