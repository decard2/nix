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
      # docker0: telepresence в --docker режиме держит daemon в контейнере;
      # intercept-handler из контейнера подключается к dev-серверу на host
      # через docker bridge — без trust порт на host'е заблокирован NixOS firewall.
      "docker0"
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
          # VK Play Cloud (стрим Mail.Ru) после TCP-handshake с Manager
          # открывает UDP audio/input на отдельных серверах. Manager
          # сообщает им ожидаемый client (IP, port). Через TUN+sing-box
          # UDP уходит из своего внутреннего сокета с другим source-port
          # (даже при EIM-NAT, который у стека mixed/system включён по
          # умолчанию — стабильность маппинга есть, но не равенство
          # исходному порту vkplaycloud). Сервер шлёт ответы на порт,
          # которого у нас нет → "Network error timeout".
          # `route_exclude_address` (sing-box ≥1.10) исключает эти
          # подсети из default-route в TUN, трафик идёт штатным kernel-
          # сокетом vkplaycloud без подмены порта — как при выключенном
          # VPN.
          #
          # Также исключаем cluster CIDR'ы Cozystack: telepresence-rootd
          # создаёт свой TUN с маршрутами на cluster-подсети, но
          # strict_route sing-box перебивает их и тянет cluster-трафик
          # в VPN — обратные пакеты intercept-туннеля теряются.
          route_exclude_address = [
            "95.163.0.0/16"   # Mail.Ru / VK Play (cgw.clgrtc.ru, *.cg.net)
            "176.112.0.0/16"  # VK Play game/audio/input servers, playkey
            "185.30.172.0/22" # Mail.Ru CDN/auth
            "10.96.0.0/16"    # cozy services CIDR (telepresence)
            "10.244.0.0/16"   # cozy pods CIDR — control plane (telepresence)
            "10.245.0.0/16"   # cozy pods CIDR — worker nodes (telepresence)
          ];
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
            process_name = [
              "transmission-daemon"
              # VK Play GameCenter — лаунчер и потоковый клиент. Стрим из
              # VK Play Cloud чувствителен к RTT, а часть бэкендов лаунчера
              # отдают 403 при выходе из не-РФ AS. Гонять оба через VLESS
              # бессмысленно.
              "GameCenterShowcase"
              "vkplaycloud"
            ];
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
                  # VK Play Cloud — стрим игр. Гео-DNS отдаёт нужный
                  # streaming-gateway по IP резолвера; через remote DNS
                  # (1.1.1.1 → VLESS-нода в Хельсинки) гейт получается
                  # европейский и сразу рвёт сессию.
                  "clgrtc.ru"         # cgw — потоковый gateway
                  "mrgcdn.ru"         # Mail.Ru group CDN (mgc)
                  "playkey.net"       # бэкенд Cloud (configurator, logstash)
                  "cg.net"            # региональные кластеры NN.cg.net
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
