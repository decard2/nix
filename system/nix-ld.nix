{ pkgs, ... }:
{
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        alsa-lib
        wayland
        vulkan-loader
        xkeyboardconfig
      ];
    };
  };
}
