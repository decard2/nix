{ pkgs, ... }:
{
  imports = [
    ./kitty.nix
    ./chrome.nix
    ./virt-manager.nix
  ];

  home.packages = with pkgs; [
    firefox
    telegram-desktop
    hunspell
    hunspellDicts.ru_RU
  ];
}
