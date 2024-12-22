{pkgs, ...}: let
  clashConfigFile = pkgs.writeText "clash-config.yaml" (builtins.readFile ./clash-config.yaml);
in {
  networking = {
    hostName = "emerald";

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    # proxy = {
    #   default = "http://127.0.0.1:7890";
    #   noProxy = "127.0.0.1,localhost,internal.domain";
    # };

    # iproute2 = {
    #   enable = true;
    # };

    useDHCP = false;
    dhcpcd.enable = false;
  };

  # services.resolved = {
  #   enable = true;
  #   dnssec = "true";
  #   fallbackDns = ["1.1.1.1" "8.8.8.8"];
  # };

  systemd.tmpfiles.rules = [
    "d /var/lib/clash-rs 0750 clash clash -"
    "C /var/lib/clash-rs/config.yaml 0640 clash clash - ${clashConfigFile}"
  ];

  # systemd.services.clash-rs = {
  #   description = "Clash-RS Proxy";
  #   after = ["network.target"];
  #   wantedBy = ["multi-user.target"];

  #   serviceConfig = {
  #     Type = "simple";
  #     User = "clash";
  #     Group = "clash";
  #     ExecStart = "${pkgs.clash-rs}/bin/clash-rs -d /var/lib/clash-rs";
  #     Restart = "on-failure";
  #     RestartSec = "10s";

  #     # Security hardening
  #     CapabilityBoundingSet = "";
  #     LockPersonality = true;
  #     NoNewPrivileges = true;
  #     PrivateDevices = true;
  #     PrivateTmp = true;
  #     ProtectHome = true;
  #     ProtectSystem = "full";
  #     ReadWritePaths = ["/var/lib/clash-rs"];
  #     RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
  #     RestrictNamespaces = true;
  #     RestrictRealtime = true;
  #     SystemCallArchitectures = "native";
  #   };
  # };

  users.users.clash = {
    isSystemUser = true;
    group = "clash";
  };
  users.groups.clash = {};

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = "/root/tailscale-key";
    extraUpFlags = [
      "--login-server=https://net.rolder.app"
      "--exit-node=finland"
    ];
  };
}
