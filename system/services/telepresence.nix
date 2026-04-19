{ pkgs, ... }:
# Telepresence (OSS) CLI + managed rootd.
# Managed-режим: rootd работает как systemd service на localhost:4037,
# CLI видит флаг --managed → не запрашивает sudo при connect.
# Upstream unit: build-aux/systemd-installer/telepresence-rootd.service.
{
  environment.systemPackages = [ pkgs.telepresence2 ];

  # TUN module usually auto-loaded, но на всякий явно: ProtectKernelModules=yes
  # запрещает загрузку в runtime, модуль должен быть уже в памяти.
  boot.kernelModules = [ "tun" ];

  systemd.services.telepresence-rootd = {
    description = "Telepresence root daemon (managed)";
    documentation = [ "https://telepresence.io/" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    environment = {
      HOME = "/var/cache/telepresence";
    };

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.telepresence2}/bin/telepresence rootd --logfile managed --address :4037 --managed";

      User = "root";
      Group = "root";

      CacheDirectory = "telepresence";
      CacheDirectoryMode = "0755";
      WorkingDirectory = "/var/cache/telepresence";
      RuntimeDirectory = "telepresence";
      RuntimeDirectoryMode = "0755";

      Restart = "always";
      RestartSec = 3;

      StandardOutput = "journal";
      StandardError = "journal";

      # Security hardening из upstream unit.
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };
}
