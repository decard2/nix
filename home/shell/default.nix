{ pkgs, ... }:
{
  imports = [
    ./ghostty.nix
  ];

  home.packages = with pkgs; [
    fzf # Для deployRoodl
    jq # Для deployRoodl
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Отключаем приветствие
      fish_config theme choose "ayu Dark"

      devenv hook fish | source

      if status is-login
          and test (tty) = /dev/tty1
          and not set -q WAYLAND_DISPLAY
          and not set -q DISPLAY
          and uwsm check may-start
          exec uwsm start hyprland-uwsm.desktop
      end
    '';
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = fromTOML (builtins.readFile ./starship.toml);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      use_flox() {
        local is_remote=0
        for arg in "$@"; do
          case "$arg" in
            -r|-r=*|--remote|--remote=*) is_remote=1 ;;
          esac
        done

        if [[ "$is_remote" == "0" && ! -d ".flox" ]]; then
          printf "direnv(use_flox): .flox directory not found\n" >&2
          printf "direnv(use_flox): Did you run 'flox init' in this directory?\n" >&2
          return 1
        fi

        direnv_load flox activate "$@" -- "$direnv" dump

        if [[ $# == 0 ]]; then
          watch_dir ".flox/env/"
          watch_file ".flox/env.json"
          watch_file ".flox/env.lock"
        fi
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
