{ pkgs, ... }:
{
  imports = [
    ./kitty.nix
    ./chromium.nix
    ./telegram.nix
    ./virt-manager.nix
    ./bridge.nix
  ];

  home.packages = with pkgs; [
    firefox
    telegram-desktop
    hunspell
    hunspellDicts.ru_RU
  ];
}
