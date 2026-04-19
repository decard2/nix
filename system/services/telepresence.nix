{ pkgs, ... }:
# Telepresence (OSS) CLI + managed rootd.
# Managed-режим: rootd работает как systemd service на localhost:4037,
# CLI видит флаг --managed → не запрашивает sudo при connect.
# Upstream unit: build-aux/systemd-installer/telepresence-rootd.service.
{
  environment.systemPackages = [ pkgs.telepresence2 ];

  # TUN module должен быть в памяти: ProtectKernelModules=yes
  # запрещает runtime загрузку.
  boot.kernelModules = [ "tun" ];

  # Default config (логирование rootd). Upstream postinstall ставит тот же.
  environment.etc."telepresence/config.yml".text = ''
    logLevels:
      rootDaemon: info
  '';

  # Upstream postinstall.sh создаёт эти пути. systemd CacheDirectory
  # делает только верхний /var/cache/telepresence, подкаталог нужен отдельно.
  systemd.tmpfiles.rules = [
    "d /var/cache/telepresence/rootd 0755 root root -"
  ];

  systemd.services.telepresence-rootd = {
    description = "Telepresence root daemon (managed)";
    documentation = [ "https://telepresence.io/" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # Telepresence пишет в $HOME при некоторых операциях.
    # /var/root (upstream default) не существует на Linux, /root закрыт ProtectHome.
    # Указываем writable путь из CacheDirectory.
    environment.HOME = "/var/cache/telepresence";

    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.telepresence2}/bin/telepresence rootd \
          --logfile managed \
          --config /etc/telepresence/config.yml \
          --address :4037 \
          --managed
      '';

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

      # Security hardening (1:1 из upstream unit).
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
      RestrictNamespaces = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };
}
