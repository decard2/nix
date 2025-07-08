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
      };

      dns = {
        servers = [
          {
            address = "https://1.1.1.1/dns-query";
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
          # Frankfurt
          server = "37.221.125.150";
          server_port = 443;
          uuid = "98d48f50-bbe8-4d43-8268-304471947824";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "emailex.io";
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
            reality = {
              enabled = true;
              # Frankfurt
              public_key = "DaUuYK1LLHW4Au__i_WlJrgOJOCs668ee3aBt65phno";
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
            rule_set = "local";
            outbound = "direct";
          }
          {
            ip_is_private = true;
            outbound = "direct";
          }
        ];
        rule_set = [
          {
            type = "inline";
            tag = "local";
            rules = [
              {
                domain_keyword = [ "rolder" ];
              }
            ];
          }
        ];
        final = "proxy";
        auto_detect_interface = true;
      };
    };
  };
}
