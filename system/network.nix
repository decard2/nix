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
        level = "error";
      };

      dns = {
        servers = [
          {
            tag = "dns-remote";
            address = "tls://1.1.1.1";
            address_resolver = "dns-local";
            address_strategy = "ipv4_only";
            detour = "proxy";
          }
          {
            tag = "dns-local";
            address = "1.1.1.1";
            detour = "direct";
          }
          {
            tag = "dns-block";
            address = "rcode://success";
          }
        ];
        rules = [
          {
            rule_set = [ "oisd-big" ];
            server = "dns-block";
            disable_cache = true;
          }
          {
            rule_set = [
              "geosite-telegram"
              "geoip-telegram"
              "torrents"
              "torrent-clients"
            ];
            server = "dns-local";
          }
          {
            rule_set = [
              "ru-bundle"
              "discord-voice-ip-list"
              "break-wall"
            ];
            server = "dns-remote";
          }
        ];
        final = "dns-local";
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
          server = "37.221.125.150";
          server_port = 443;
          uuid = "98d48f50-bbe8-4d43-8268-304471947824";
          flow = "xtls-rprx-vision";
          tls = {
            enabled = true;
            server_name = "www.twitch.tv";
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
            rule_set = [ "oisd-big" ];
            action = "reject";
            method = "drop";
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
            tag = "oisd-big";
            format = "binary";
            url = "https://github.com/burjuyz/RuRulesets/raw/main/ruleset-domain-oisd_big.srs";
          }
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
                  "claude.ai.com"
                  "integrate.api.nvidia.com"
                  "llm.zed.dev"
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

        auto_detect_interface = true;
      };

      experimental = {
        cache_file = {
          enabled = true;
        };
      };
    };
  };
}
