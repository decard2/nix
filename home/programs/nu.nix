{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    # Базовые настройки
    extraConfig = ''
      $env.EDITOR = 'zeditor'
      $env.VISUAL = 'zeditor'

      # Wayland specific
      $env.XDG_SESSION_TYPE = 'wayland'
      $env.XDG_CURRENT_DESKTOP = 'Hyprland'
      $env.XDG_SESSION_DESKTOP = 'Hyprland'
    '';

    # Приветствие при запуске
    loginFile.text = ''
      echo "Здарова, хозяин! 🚀"
    '';

    # Алиасы для удобства
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      ".." = "cd ..";
      "..." = "cd ../..";
      c = "clear";

      rebuild = "sudo nixos-rebuild switch --flake .#emerald";
      update = "nix flake update";
    };
  };
}
