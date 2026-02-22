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

  home.packages = with pkgs; [
    inputs.flox.packages.${pkgs.stdenv.hostPlatform.system}.flox
    devbox
    gh
  ];

  programs = {
    bun.enable = true;

    git = {
      enable = true;
      settings = {
        user.name = "decard";
        user.email = "mail@decard.space";
        init.defaultBranch = "main";
        safe.directory = "/home/decard/nix";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        "github.com" = {
          identityFile = "~/.ssh/decard-github";
          extraOptions = {
            AddKeysToAgent = "yes";
            StrictHostKeyChecking = "yes";
          };
        };
      };
    };
  };

  services.ssh-agent.enable = true;

  home.activation = {
    sshPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.ssh
      $DRY_RUN_CMD chmod 700 $HOME/.ssh
    '';
  };
}
