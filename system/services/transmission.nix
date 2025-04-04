{ pkgs, ... }:
{
  services.transmission = {
    enable = true;
    user = "decard";
    group = "users";
    package = pkgs.transmission_4;
    settings = {
      download-dir = "/home/decard/torrents/downloads";
      watch-dir = "/home/decard/torrents/torrents";
      watch-dir-enabled = true;

      rpc-enabled = true;
      rpc-port = 9091;
      rpc-whitelist = "127.0.0.1";
      rpc-username = "";
      rpc-password = "";

      # Оптимизации
      ratio-limit = 2.0;
      ratio-limit-enabled = false;

      incomplete-dir = "/home/decard/torrents/downloads/.incomplete";
      incomplete-dir-enabled = true;
      peer-port = 51413;
      peer-port-random-on-start = false;
    };
  };

  # Добавляем нужные пакеты в систему
  environment.systemPackages = with pkgs; [
    transmission_4
    tremc
  ];

  # Создаём нужные директории при установке
  systemd.tmpfiles.rules = [
    "d /home/decard/torrents/downloads 0755 decard users -"
    "d /home/decard/torrents/torrents 0755 decard users -"
    "d /home/decard/torrents/downloads/.incomplete 0755 decard users -"
  ];
}
