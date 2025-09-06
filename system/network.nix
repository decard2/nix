{
  # Разрешаем IPv6 privacy extensions
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.enp0s20f0u3u4.use_tempaddr" = 2;
  };

  networking = {
    hostName = "emerald";
    wireless.iwd.enable = true;
    firewall.trustedInterfaces = [ "virbr0" ];
  };

  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "error";
      };

      dns = {
        servers = [
          {
            tag = "remote";
            type = "tls";
            server = "1.1.1.1";
          }
          {
            tag = "local";
            type = "local";
          }
        ];
        strategy = "ipv4_only";
        rules = [
          {
            rule_set = [
              "torrents"
              "torrent-clients"
            ];
            server = "local";
          }
        ];
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = "tun-freedom";
          address = [
            "172.16.0.1/30"
            "fd00::1/126"
          ];
          auto_route = true;
          auto_redirect = true;
          strict_route = true;
        }
      ];

      outbounds = [
        {
          type = "direct";
          tag = "direct";
        }
        {
          tag = "proxy";
          type = "vless";
          # Stockholm
          # server = "sw.rolder.net";
          # Helsinki
          server = "fi.rolder.net";
          server_port = 443;
          uuid = "98d48f50-bbe8-4d43-8268-304471947824";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            # Stockholm
            # server_name = "sw.rolder.net";
            # Helsinki
            server_name = "fi.rolder.net";
            utls = {
              enabled = true;
              fingerprint = "chrome";
            };
            reality = {
              enabled = true;
              public_key = "DaUuYK1LLHW4Au__i_WlJrgOJOCs668ee3aBt65phno";
              short_id = "6a06f4ce3afb4d9f";
            };
          };
        }
      ];

      route = {
        rules = [
          {
            action = "sniff";
          }
          {
            protocol = "dns";
            action = "hijack-dns";
          }
          {
            clash_mode = "Direct";
            outbound = "direct";
          }
          {
            rule_set = "torrent-clients";
            outbound = "direct";
          }
        ];

        rule_set = [
          {
            type = "remote";
            tag = "torrent-clients";
            format = "binary";
            url = "https://raw.githubusercontent.com/legiz-ru/sb-rule-sets/main/torrent-clients.srs";
            download_detour = "proxy";
          }
          {
            type = "inline";
            tag = "torrents";
            rules = [
              {
                source_port = [ 51413 ];
              }
            ];
          }
        ];
        default_domain_resolver = "local";
        auto_detect_interface = true;
        final = "proxy";
      };

      experimental = {
        cache_file = {
          enabled = true;
          store_rdrc = true;
        };
      };
    };
  };
}
