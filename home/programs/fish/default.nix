{ ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Отключаем приветствие
      fish_config theme choose "ayu Dark"
      check_and_start_hyprland
    '';
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ./starship.toml);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      use_flox() {
        eval "$(flox activate)"
      }
    '';
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
}
