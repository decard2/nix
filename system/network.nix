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
              "geosite-telegram"
              "geoip-telegram"
              "torrents"
              "torrent-clients"
            ];
            server = "local";
          }
          {
            rule_set = [
              "ru-bundle"
              "discord-voice-ip-list"
              "break-wall"
            ];
            server = "remote";
            client_subnet = "185.37.56.241/24";
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
          # Frankfurt
          # server = "37.221.125.150";
          # Bucharest
          # server = "45.67.34.30";
          # Stockholm
          server = "34.51.201.70";
          server_port = 443;
          uuid = "98d48f50-bbe8-4d43-8268-304471947824";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            # Frankfurt/Stockholm
            server_name = "www.microsoft.com";
            # Bucharest
            # server_name = "www.yahoo.com";
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
          {
            clash_mode = "Global";
            outbound = "proxy";
          }
          {
            rule_set = [
              "geosite-telegram"
              "geoip-telegram"
            ];
            outbound = "direct";
          }
          {
            rule_set = [
              "ru-bundle"
              "discord-voice-ip-list"
              "break-wall"
            ];
            outbound = "proxy";
          }
        ];

        rule_set = [
          {
            type = "remote";
            tag = "geosite-telegram";
            format = "binary";
            url = "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geosite/telegram.srs";
          }
          {
            type = "remote";
            tag = "geoip-telegram";
            format = "binary";
            url = "https://github.com/MetaCubeX/meta-rules-dat/raw/sing/geo/geoip/telegram.srs";
          }
          {
            type = "remote";
            tag = "ru-bundle";
            format = "binary";
            url = "https://github.com/legiz-ru/sb-rule-sets/raw/main/ru-bundle.srs";
          }
          {
            type = "remote";
            tag = "discord-voice-ip-list";
            format = "binary";
            url = "https://github.com/legiz-ru/sb-rule-sets/raw/main/discord-voice-ip-list.srs";
          }
          {
            type = "remote";
            tag = "torrent-clients";
            format = "binary";
            url = "https://raw.githubusercontent.com/legiz-ru/sb-rule-sets/main/torrent-clients.srs";
          }
          {
            type = "inline";
            tag = "break-wall";
            rules = [
              {
                domain = [ "2ip.io" ];
                domain_keyword = [
                  "openai"
                  "anthropic"
                  "claude"
                  "zed"
                ];
                domain_suffix = [
                  "perplexity.ai"
                  "chatgpt.com"
                  "auth0.com"
                  "client-api.arkoselabs.com"
                  "events.statsigapi.net"
                  "featuregates.org"
                  "identrust.com"
                  "intercom.io"
                  "intercomcdn.com"
                  "oaistatic.com"
                  "oaiusercontent.com"
                  "openai.com"
                  "openaiapi-site.azureedge.net"
                  "sentry.io"
                  "stripe.com"
                  "bard.google.com"
                  "gemini.google.com"
                  "makersuite.google.com"
                  "anthropic.com"
                  "statsig.anthropic.com"
                  "console.anthropic.com"
                  "api.anthropic.com"
                  "claude.ai.com"
                  "integrate.api.nvidia.com"
                  "llm.zed.dev"
                  "google-analytics.com"
                  "googlesyndication.com"
                  "gstatic.com"
                  "doubleclick.net"
                ];
              }
            ];
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
      };

      experimental = {
        cache_file = {
          enabled = true;
          store_rdrc = true;
        };
        clash_api = {
          default_mode = "Enhanced";
        };
      };
    };
  };
}
