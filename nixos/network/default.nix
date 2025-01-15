{ pkgs, ... }:
{
  # Разрешаем IPv6 privacy extensions
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.enp0s20f0u3u4.use_tempaddr" = 2;
  };

  networking = {
    hostName = "emerald";
    dhcpcd.extraConfig = "nohook resolv.conf";
    nameservers = [
      "::1"
      "127.0.0.1"
    ];
    wireless.iwd.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 51413 ];
      allowedUDPPorts = [ 51413 ];
      extraCommands = ''
        # Разрешаем входящие соединения для торрентов
        iptables -A INPUT -p tcp --dport 51413 -j ACCEPT
        iptables -A INPUT -p udp --dport 51413 -j ACCEPT
        # Разрешаем исходящие соединения
        iptables -A OUTPUT -p tcp --dport 51413 -j ACCEPT
        iptables -A OUTPUT -p udp --dport 51413 -j ACCEPT
      '';
    };
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      listen_addresses = [
        "[::1]:53"
        "127.0.0.1:53"
      ];

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig.StateDirectory = "dnscrypt-proxy";

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "warn";
      };
      dns = {
        servers = [
          {
            tag = "dns-remote";
            address = "tls://[2606:4700:4700::1111]";
          }
          {
            tag = "dns-direct";
            address = "local";
            detour = "direct";
          }
          {
            address = "rcode://success";
            tag = "dns-block";
          }
        ];
        rules = [
          {
            query_type = [
              32
              33
            ];
            server = "dns-block";
          }
          {
            domain_suffix = [ ".lan" ];
            server = "dns-block";
          }
        ];
        strategy = "prefer_ipv6";
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
          server_port = 443;
          uuid = "84466b63-d52c-414c-852f-6c5856028248";
          flow = "xtls-rprx-vision";
          network = "tcp";
          tls = {
            enabled = true;
            server_name = "www.tallinn.ee";
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
            geosite = [ "reddit" ];
            outbound = "direct";
          }
          {
            network = "udp";
            port = [
              135
              137
              138
              139
              5353
            ];
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
            protocol = "dns";
            outbound = "dns-out";
          }
          {
            port = [ 123 ];
            outbound = "direct";
            network = "udp";
          }
          {
            port = [ 51413 ];
            outbound = "direct";
            network = "tcp";
          }
        ];
      };
    };
  };

  # Нужные правила для маршрутизации
  systemd.services.sing-box = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
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
}
