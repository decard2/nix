{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    libxkbcommon
    xkeyboardconfig
    lsof
    intel-vaapi-driver
    intel-media-driver
    vpl-gpu-rt
    mesa
    sox
    ghostty
    inputs.max-messenger.packages.${pkgs.system}.default
  ];
}
