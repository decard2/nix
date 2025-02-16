{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./zed
    ./roodl.nix
  ];

  programs = {
    git = {
      enable = true;
      userName = "decard";
      userEmail = "mail@decard.space";
    };

    ssh = {
      enable = true;

      matchBlocks = {
        "github.com" = {
          host = "github.com";
          identityFile = "~/.ssh/id_ed25519";
          extraOptions = {
            AddKeysToAgent = "yes";
            StrictHostKeyChecking = "no";
          };
        };
      };
    };
  };

  services.ssh-agent.enable = true;

  home.file = {
    ".ssh/id_ed25519" = {
      source = ./keys/id_ed25519;
      onChange = "chmod 600 $TARGET";
    };
    ".ssh/id_ed25519.pub" = {
      source = ./keys/id_ed25519.pub;
      onChange = "chmod 644 $TARGET";
    };
  };

  home.activation = {
    sshPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.ssh
      $DRY_RUN_CMD chmod 700 $HOME/.ssh
    '';
  };

  home.packages = with pkgs; [
    lazygit
    inputs.flox.packages.${pkgs.system}.default
  ];
}
