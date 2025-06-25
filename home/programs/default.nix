{ pkgs, ... }:
{
  imports = [
    ./kitty.nix
    ./chromium.nix
    ./virt-manager.nix
    ./bridge.nix
    ./yandex-browser.nix
  ];

  home.packages = with pkgs; [
    firefox
    telegram-desktop
    hunspell
    hunspellDicts.ru_RU
  ];
}
