{ pkgs, ... }:
{
  programs.nushell = {
    enable = true;
    envFile.source = ./env.nu;
    shellAliases = import ./aliases.nix;
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      whitelist = {
        prefix = [
          "$HOME/projects"
          "$HOME/nix"
        ];
      };
      warn_timeout = "1m";
    };
  };

  home.packages = with pkgs; [ carapace ];
}
