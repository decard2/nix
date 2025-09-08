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
    lazygit
    inputs.flox.packages.${pkgs.system}.flox
    devenv
  ];

  programs = {
    bun.enable = true;

    git = {
      enable = true;
      userName = "decard";
      userEmail = "mail@decard.space";
      extraConfig = {
        init.defaultBranch = "main";
        safe.directory = "/home/decard/nix";
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        # dayreon github
        "decard" = {
          host = "decard";
          hostname = "github.com";
          identityFile = "~/.ssh/id_ed25519";
          extraOptions = {
            AddKeysToAgent = "yes";
            StrictHostKeyChecking = "yes";
          };
        };
        # rolderdevs
        "rolderdevs" = {
          host = "github.com";
          identityFile = "~/.ssh/rolderdev-github";
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
