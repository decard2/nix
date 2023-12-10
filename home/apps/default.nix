{ inputs, config, pkgs, ... }:
{
  imports = [
    ./vscode.nix
    ./firefox.nix
  ];
  home.packages = with pkgs; [
    shadowsocks-rust
    firefox
    telegram-desktop
  ];
}
