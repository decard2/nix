{pkgs, ...}: let
  clashConfigFile = pkgs.writeText "clash-config.yaml" (builtins.readFile ./clash-config.yaml);
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

  services.resolved.enable = true;

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
      };
      dns = {
        fakeip = {
          enabled = true;
          inet4_range = "198.18.0.0/15";
          inet6_range = "fc00::/18";
        };
        servers = [
          {
            tag = "dns-remote";
            address = "1.1.1.1";
            detour = "proxy";
          }
          {
            tag = "dns-direct";
            address = "local";
            detour = "direct";
          }
          {
            address = "fakeip";
            tag = "dns-fake";
          }
          {
            address = "rcode://success";
            tag = "dns-block";
          }
        ];
        rules = [
          {
            query_type = [32 33];
            server = "dns-block";
          }
          {
            domain_suffix = [".lan"];
            server = "dns-block";
          }
          {
            inbound = "tun-in";
            server = "dns-fake";
          }
        ];
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "singbox-tun";
          inet4_address = "172.19.0.1/28";
          inet6_address = "fdfe:dcba:9876::1/126";
          mtu = 9000;
          auto_route = true;
          strict_route = false;
          stack = "gvisor";
          endpoint_independent_nat = true;
          sniff = true;
        }
      ];

      outbounds = [
        {
          type = "vless";
          tag = "proxy";
          server = "95.164.8.24";
          server_port = 3567;
          uuid = "84466b63-d52c-414c-852f-6c5856028248";
          flow = "";
          network = "tcp";
          tls = {
            enabled = true;
            server_name = "ipinfo.io";
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
            reality = {
              enabled = true;
              public_key = "uVvacfSbGNEF4ELVeUEjXGyv3TWUjKu80QTDDQAn8kA";
              short_id = "e6de3a5883656f31";
            };
          };
        }
        {
          type = "block";
          tag = "block";
        }
        {
          type = "direct";
          tag = "direct";
        }
        {
          type = "dns";
          tag = "dns-out";
        }
      ];

      route = {
        final = "proxy";
        auto_detect_interface = true;
        rules = [
          {
            domain_suffix = [
              "reddit.com"
              "redd.it"
              "redditstatic.com"
              "redditmedia.com"
            ];
            outbound = "direct";
          }
          {
            network = "udp";
            port = [135 137 138 139 5353];
            outbound = "block";
          }
          {
            ip_cidr = [
              "224.0.0.0/3"
              "ff00::/8"
            ];
            outbound = "block";
          }
          {
            source_ip_cidr = [
              "224.0.0.0/3"
              "ff00::/8"
            ];
            outbound = "block";
          }
          {
            port = 53;
            outbound = "dns-out";
          }
        ];
      };
    };
  };

  # Нужные правила для маршрутизации
  systemd.services.sing-box = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStartPre = pkgs.writeScript "sing-box-pre" ''
        #!${pkgs.bash}/bin/bash
        set -e
        # Добавляем правила маршрутизации
        ${pkgs.iproute2}/bin/ip rule add pref 8999 fwmark 514 table main || true
        ${pkgs.iproute2}/bin/ip -6 rule add pref 8999 fwmark 514 table main || true

        # Добавляем правила файрвола
        ${pkgs.iptables}/bin/iptables -I INPUT -s 172.19.0.2 -d 172.19.0.1 -p tcp -j ACCEPT
        ${pkgs.iptables}/bin/ip6tables -I INPUT -s fdfe:dcba:9876::2 -d fdfe:dcba:9876::1 -p tcp -j ACCEPT
      '';
      ExecStopPost = pkgs.writeScript "sing-box-post" ''
        #!${pkgs.bash}/bin/bash
        # Удаляем правила файрвола
        ${pkgs.iptables}/bin/iptables -D INPUT -s 172.19.0.2 -d 172.19.0.1 -p tcp -j ACCEPT || true
        ${pkgs.iptables}/bin/ip6tables -D INPUT -s fdfe:dcba:9876::2 -d fdfe:dcba:9876::1 -p tcp -j ACCEPT || true

        # Удаляем правила маршрутизации
        ${pkgs.iproute2}/bin/ip rule del fwmark 514 || true
        ${pkgs.iproute2}/bin/ip -6 rule del fwmark 514 || true
      '';
      Restart = "on-failure";
      RestartSec = "3";
    };
  };

  # Файрвол
  networking.firewall = {
    enable = true;
  };
}
