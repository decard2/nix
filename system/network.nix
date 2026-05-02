{
  # Разрешаем IPv6 privacy extensions
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.enp0s20f0u3u4.use_tempaddr" = 2;
  };

  networking = {
    hostName = "emerald";
    wireless.iwd.enable = true;
    firewall.trustedInterfaces = [
      "virbr0"
      "wgd+"
    ];
    localCommands = ''
      ip rule add ipproto icmp lookup main preference 100 2>/dev/null || true
      ip rule add ipproto udp dport 123 lookup main preference 99 2>/dev/null || true
    '';
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
              "direct"
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
          exclude_interface = [ "docker0" ];
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
          server = "fipro.rolder.net";
          server_port = 443;
          uuid = "98d48f50-bbe8-4d43-8268-304471947824";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "fipro.rolder.net";
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
            ip_is_private = true;
            outbound = "direct";
          }
          {
            process_name = [ "transmission-daemon" ];
            outbound = "direct";
          }
          {
            rule_set = "direct";
            outbound = "direct";
          }
        ];

        rule_set = [
          {
            type = "inline";
            tag = "direct";
            rules = [
              {
                domain_suffix = [
                  "reddit.com"
                  # Подпись документов российским КЭП — CRL/OCSP/CA-cert URLs
                  # должны идти напрямую, иначе VLESS-прокси режет соединение
                  # к pki.tax.gov.ru/cdp.tax.gov.ru/reestr-pki.ru, и Cades
                  # plugin таймаутит на проверке цепочки → "Не действителен".
                  "tax.gov.ru"        # ФНС: pki, cdp, ocsp, crt
                  "nalog.ru"          # ФНС: альтернативный домен УЦ
                  "reestr-pki.ru"     # Минцифры: корневой CA + reestr
                  "cryptopro.ru"      # КриптоПро: cades demo, updates
                  "kontur.ru"         # Контур: extern, диадок
                  "kontur-extern.ru"
                  "kontur-ca.ru"
                  "tochka.com"        # Точка Банк
                  # VK Play GameCenter — лаунчер тянет апдейты и контент
                  # через российский CDN, который у некоторых VLESS-нод
                  # выходит за пределы РФ → срабатывает гео-блок.
                  "vkplay.ru"         # static.gc, dl, сайт
                  "my.games"          # legacy-CDN VK Play GameCenter
                ];
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
