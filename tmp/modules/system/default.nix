{ config, pkgs, ... }:

{
  imports = [
    ./btrfs.nix
    ./nixos-snapshots.nix
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  system.activationScripts.snapshotOnUpdate = ''
      if [ -e /run/current-system ]; then
        ${pkgs.systemd}/bin/systemctl start nixos-update-snapshots
      fi
    '';
}
