{ config, pkgs, ... }: {

  # Создаем директорию для конфигов WireGuard
  home.file.".config/wireguard/" = {
    recursive = true;
    source = ./wireguard;
  };
}
