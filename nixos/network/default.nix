{pkgs, ...}: let
  routeScript = pkgs.writeScriptBin "add-excluded-routes" ''
    #!${pkgs.runtimeShell}

    # Ждём DNS
    while ! systemctl is-active systemd-resolved >/dev/null 2>&1 || \
          ! resolvectl status | grep "Current DNS Server" >/dev/null 2>&1; do
      sleep 1
    done

    # Добавляем маршруты
    for domain in ${builtins.toString (import ./excluded-domains.nix)}; do
      dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | \
        while read -r ip; do
          ip route add "$ip/32" via 192.168.0.1 dev wlan0 metric 50 2>/dev/null || true
        done
    done
  '';

  clashConfigFile = pkgs.writeText "clash-config.yaml" (builtins.readFile ./clash-config.yaml);
in {
  networking = {
    hostName = "emerald";

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    proxy = {
      default = "http://127.0.0.1:7890";
      noProxy = "127.0.0.1,localhost,internal.domain,github.com,githubusercontent.com,raw.githubusercontent.com,nixos.org,cache.nixos.org";
    };

    useDHCP = false;
    dhcpcd.enable = false;
  };

  systemd.services.exclude-routes = {
    description = "Add excluded routes";
    after = ["NetworkManager.service"];
    wants = ["NetworkManager.service"];
    wantedBy = ["multi-user.target"];

    path = with pkgs; [iproute2 dnsutils systemd];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${routeScript}/bin/add-excluded-routes";
    };
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    fallbackDns = ["1.1.1.1" "8.8.8.8"];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/clash-rs 0750 clash clash -"
    "C /var/lib/clash-rs/config.yaml 0640 clash clash - ${clashConfigFile}"
  ];

  systemd.services.clash-rs = {
    description = "Clash-RS Proxy";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "clash";
      Group = "clash";
      ExecStart = "${pkgs.clash-rs}/bin/clash-rs -f /var/lib/clash-rs/config.yaml -d /var/lib/clash-rs";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      CapabilityBoundingSet = "";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "full";
      ReadWritePaths = ["/var/lib/clash-rs"];
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
    };
  };

  users.users.clash = {
    isSystemUser = true;
    group = "clash";
  };
  users.groups.clash = {};
}
