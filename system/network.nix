{ inputs, ... }:
let
  unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
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
  };

  services.sing-box = {
    enable = true;
    package = unstable.sing-box;
    settings = {
      log = {
        level = "error";
        timestamp = true;
      };

      dns = {
        servers = [
          {
            tag = "cloudflare-dns";
            address = "https://1.1.1.1/dns-query";
            detour = "proxy";
          }
        ];
      };

      inbounds = [
        {
          type = "tun";
          interface_name = "singbox-tun";
          address = [ "172.16.0.1/30" "fdfe:dcba:9876::1/126" ];
          auto_route = true;
          auto_redirect = true;
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
          # packet_encoding = "xudp";
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
        rules = [
          {
            action = "route";
            rule_set = "local";
            outbound = "direct";
          }
          {
            action = "sniff";
          }
          {
            protocol = "bittorrent";
            action = "route";
            outbound = "direct";
          }
          {
            protocol = "dns";
            action = "hijack-dns";
          }
        ];
        rule_set = [
          {
            tag = "local";
            type = "inline";
            rules = [
              { domain_suffix = [".ru"]; }
              { domain_keyword = ["rolder" "reddit"]; }
            ];
          }
        ];
        auto_detect_interface = true;
        final = "proxy";
      };
    };
  };
}
