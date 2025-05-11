let
  tunName = "tun-proxy";
in
{
  # Разрешаем IPv6 privacy extensions
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.enp0s20f0u3u4.use_tempaddr" = 2;
  };

  networking = {
    hostName = "emerald";
    wireless.iwd.enable = true;
    firewall.trustedInterfaces = [ tunName ];
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
            # tag = "cloudflare";
            address = "tcp://1.1.1.1";
            detour = "direct";
          }
        ];
      };

      inbounds = [
        {
          type = "tun";
          tag = "tun-in";
          interface_name = tunName;
          address = [ "172.16.0.1/30" "fd00::1/126"];
          mtu = 1492;
          auto_route = true;
          auto_redirect = true;
          # strict_route = true;
          # stack = "system";
        }
      ];

      outbounds = [
        {
          tag = "proxy";
          type = "vless";
          server = "185.156.109.205";
          server_port = 8443;
          uuid = "84466b63-d52c-414c-852f-6c5856028248";
          flow = "xtls-rprx-vision";
          connect_timeout = "30s";
          tcp_fast_open = true;
          tcp_multi_path = true;
          tls = {
            enabled = true;
            server_name = "www.visitstockholm.com";
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
        rule_set = [
          {
            tag = "local";
            type = "inline";
            rules = [
              { domain_suffix = [".ru"]; }
              { domain_keyword = ["rolder" "reddit"]; }
              { domain = ["www.reddit.com"]; }
            ];
          }
        ];
          rules = [
            {
              action = "route";
              rule_set = "local";
              outbound = "direct";
            }
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
              action = "route";
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
