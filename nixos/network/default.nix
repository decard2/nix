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
in {
  networking = {
    hostName = "emerald";

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
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
}
