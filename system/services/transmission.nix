{ pkgs, ... }:
{
  services.transmission = {
    enable = true;
    user = "decard";
    group = "users";
    package = pkgs.transmission_4;
    settings = {
      download-dir = "/home/decard/torrents/downloads";
      watch-dir-enabled = true;
      watch-dir = "/home/decard/torrents/torrents";
      incomplete-dir-enabled = true;
      incomplete-dir = "/home/decard/torrents/.incomplete";

      rpc-enabled = true;
      rpc-port = 9091;
      rpc-whitelist = "127.0.0.1";
      rpc-username = "";
      rpc-password = "";

      # Оптимизации
      ratio-limit = 2.0;
      ratio-limit-enabled = false;

      peer-port = 51413;
      peer-port-random-on-start = false;
    };
  };

  systemd.user.tmpfiles.users.decard.rules = [
    "d /home/decard/torrents/downloads 0755 decard users -"
    "d /home/decard/torrents/torrents 0755 decard users -"
    "d /home/decard/torrents/.incomplete 0755 decard users -"
  ];

  # Добавляем нужные пакеты в систему
  environment.systemPackages = with pkgs; [
    transmission_4
    tremc
  ];
}
