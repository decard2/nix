{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libxkbcommon
    xorg.xkeyboardconfig
    lsof
  ];
}
