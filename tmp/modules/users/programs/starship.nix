{ config, pkgs, ... }:

{
  home-manager.users.decard = { pkgs, ... }: {
    programs.starship = {
      enable = true;
      # Работает со всеми шеллами!
      enableZshIntegration = true;
      enableNushellIntegration = true;

      settings = {
        # Общие настройки
        add_newline = false;

        # Модули в промпте
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };

        directory = {
          truncation_length = 3;
          style = "bold blue";
        };

        git_branch = {
          format = "[$symbol$branch]($style) ";
          style = "bold purple";
        };

        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state( \($name\))]($style) ";
        };

        # Время выполнения команды, если больше 2000мс
        cmd_duration = {
          min_time = 2000;
          format = "took [$duration](bold yellow)";
        };

        # Статус последней команды
        status = {
          disabled = false;
          format = "[$status]($style) ";
        };
      };
    };
  };
}
