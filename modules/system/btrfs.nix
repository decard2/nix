{ config, lib, pkgs, ... }:

{
  # Ставим базовые тулзы для BTRFS
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize # для анализа сжатия
    snapper # для управления снапшотами
  ];

  # Включаем сервисы для автоматического обслуживания BTRFS
  services = {
    # Автоматическая дефрагментация
    btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/" "/home" "/nix" ];
      interval = "weekly";
    };

    # Снапшоты через snapper
    snapper = {
      enable = true;
      # Конфиг для корневой ФС
      configs = {
        root = {
          ALLOW_USERS = [ "decard" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_MIN_AGE = "1800";
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "2";
          TIMELINE_LIMIT_YEARLY = "0";
        };
        home = {
          ALLOW_USERS = [ "decard" ];
          SUBVOLUME = "/home";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_MIN_AGE = "1800";
          TIMELINE_LIMIT_HOURLY = "5";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "4";
          TIMELINE_LIMIT_MONTHLY = "2";
          TIMELINE_LIMIT_YEARLY = "0";
        };
      };
    };
  };

  # Автоматическая очистка снапшотов
  systemd.services = {
    btrfs-maintenance = {
      description = "BTRFS maintenance tasks";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=85 -musage=85 /
          ${pkgs.btrfs-progs}/bin/btrfs scrub start -B /
        '';
      };
    };
  };

  systemd.timers.btrfs-maintenance = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };

  # Настройки для оптимальной производительности
  boot.kernelParams = [
    "noatime"
    "space_cache=v2"
    "commit=120" # Немного агрессивнее синхронизация для надёжности
    "autodefrag" # Автоматическая дефрагментация
  ];
}
