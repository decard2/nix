{pkgs, ...}: {
  services.transmission = {
    enable = true;
    user = "decard"; # твой пользователь
    group = "users";
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
      speed-limit-up = 1000;
      speed-limit-down = 2000;
      ratio-limit = 2.0;
      ratio-limit-enabled = true;

      encryption = 1;
      incomplete-dir = "/home/decard/torrents/downloads/.incomplete";
      incomplete-dir-enabled = true;
      peer-port = 51413;
      peer-port-random-on-start = false;

      # Скрипт уведомлений
      script-torrent-done-enabled = true;
      script-torrent-done-filename = "${pkgs.writeScript "torrent-done" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.libnotify}/bin/notify-send "Торрент загружен" "$TR_TORRENT_NAME"
      ''}";
    };
  };

  # Добавляем нужные пакеты в систему
  environment.systemPackages = with pkgs; [
    transmission
    stig
    tremc
  ];

  # Создаём нужные директории при установке
  systemd.tmpfiles.rules = [
    "d /home/decard/torrents/downloads 0755 decard users -"
    "d /home/decard/torrents/torrents 0755 decard users -"
    "d /home/decard/torrents/downloads/.incomplete 0755 decard users -"
  ];
}
