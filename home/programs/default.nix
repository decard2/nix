{ pkgs, ... }:
{
  imports = [
    ./kitty.nix
    ./browsers.nix
    ./telegram.nix
    ./virt-manager.nix
  ];

  home.packages = with pkgs; [
    firefox
    telegram-desktop
    hunspell
    hunspellDicts.ru_RU
  ];
}
