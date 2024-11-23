{ config, pkgs, ... }:

{
  home-manager.users.decard = { pkgs, ... }: {
    programs.nushell = {
      enable = true;

      extraConfig = ''
        # Алиасы
        alias ll = ls -l
        alias g = git

        # Твой любимый промпт
        let-env PROMPT_COMMAND = { ||
          build-string [
            (date format '%H:%M:%S')
            " | "
            ($env.PWD)
            "> "
          ]
        }

        # Добавим немного удобных функций
        def update [] {
          sudo nixos-rebuild switch
        }

        # Алиасы для работы со снапшотами
        alias nsr = sudo nixos-safe-rebuild
        alias nrb = sudo nixos-rollback
        alias nls = snapper list    # посмотреть все снапшоты
        alias ndf = snapper diff    # показать разницу между снапшотами
      '';

      extraEnv = ''
        # Переменные окружения
        let-env PATH = ($env.PATH | append "~/.local/bin")
      '';
    };
  };
}
