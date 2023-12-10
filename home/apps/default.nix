{ inputs, config, pkgs, ... }:
{
  imports = [
    ./vscode.nix
  ];
  home.packages = with pkgs; [
    shadowsocks-rust
    firefox
    telegram-desktop
  ];
}
