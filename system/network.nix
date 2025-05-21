{
  # Разрешаем IPv6 privacy extensions
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.enp0s20f0u3u4.use_tempaddr" = 2;
  };

  networking = {
    hostName = "emerald";
    wireless.iwd.enable = true;
  };

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "warn";
        timestamp = true;
      };

      dns = {
        servers = [
          {
            address = "tcp://1.1.1.1";
            detour = "direct";
          }
        ];
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "tun-proxy";
          address = [
            "172.16.0.1/30"
            "fd00::1/126"
          ];
          auto_route = true;
          auto_redirect = true;
        }
      ];

      outbounds = [
        {
          tag = "proxy";
          type = "vless";
          server = "helsinki.rolder.net";
          server_port = 443;
          uuid = "4ad49612-0a70-47c3-9900-f47b88c36bc0";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "www.microsoft.com";
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
            reality = {
              enabled = true;
              public_key = "1RmhIVt9cczpKnnXpqM_i4ODjk7yXUomcIs2QJhA4U0";
              short_id = "6a06f4ce3afb4d9f";
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
            inbound = "tun-in";
            action = "sniff";
          }
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            protocol = "bittorrent";
            outbound = "direct";
          }
          {
            domain_keyword = [
              "rolder"
              "reddit"
            ];
            outbound = "direct";
          }
          {
            ip_is_private = true;
            outbound = "direct";
          }
        ];
        final = "proxy";
        auto_detect_interface = true;
      };
    };
  };
}
