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
  environment.systemPackages = with pkgs; [ ];
  system.stateVersion = "23.11";
}
