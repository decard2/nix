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

    nameservers = [ "127.0.0.1" ];

    wireless.iwd.enable = true;

    firewall = {
      enable = true;
      # torrents
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

  environment.systemPackages = with pkgs; [
    dnsproxy
  ];

  systemd.services.dnsproxy = {
    description = "dnsproxy";
    serviceConfig.ExecStart = "${pkgs.dnsproxy}/bin/dnsproxy -l 127.0.0.1 -u https://cloudflare-dns.com/dns-query -b 1.1.1.1 --cache --cache-optimistic";
    wantedBy = [ "multi-user.target" ];
  };

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "warn";
      };

      inbounds = [
        {
          type = "tun";
          interface_name = "singbox-tun";
          inet4_address = "172.19.0.1/28";
          inet6_address = "fdfe:dcba:9876::1/126";
          auto_route = true;
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
          type = "direct";
          tag = "direct";
        }
      ];

      route = {
        rules = [
          {
            protocol = "dns";
            outbound = "direct";
          }
          {
            geosite = [ "reddit" ];
            outbound = "direct";
          }
          {
            port = [ 51413 ];
            outbound = "direct";
          }
        ];
        auto_detect_interface = true;
        final = "proxy";
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
