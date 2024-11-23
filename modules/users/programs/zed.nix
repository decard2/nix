{ config, pkgs, ... }:

{
  home-manager.users.decard = { pkgs, ... }: {
    # Устанавливаем Zed
    home.packages = with pkgs.unstable; [ zed ];

    # Линкуем конфиги
    xdg.configFile."zed" = {
      source = ../../../config/zed;
      recursive = true;
    };
  };
}
