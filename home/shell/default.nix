{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf # Для deployRoodl
    jq # Для deployRoodl
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Отключаем приветствие
      fish_config theme choose "ayu Dark"

      uwsm check may-start
      if test $status = 0; and not test $DISPLAY; and not test $WAYLAND_DISPLAY
          exec uwsm start hyprland-uwsm.desktop
      end
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
      warn_timeout = "2m";
    };
  };
}
