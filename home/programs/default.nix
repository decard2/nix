{ pkgs, ... }:
{
  imports = [
    ./chrome.nix
    ./virt-manager.nix
    ./vkplay-gamecenter.nix
    ./yandex-browser.nix
  ];

  home.packages = with pkgs; [
    firefox
    telegram-desktop
    hunspell
    hunspellDicts.ru_RU
  ];
}
