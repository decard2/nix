{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./base.nix
    ./desktop.nix
    ./virt.nix
  ];
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    wineWowPackages.staging
    vscode-extensions.chenglou92.rescript-vscode
  ];
  system.stateVersion = "23.11";
}
