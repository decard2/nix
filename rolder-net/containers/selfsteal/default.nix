# Selfsteal module - Caddy для маскировки Reality трафика
{
  hostConfig,
  ...
}:

{
  # Caddy контейнер для selfsteal
  virtualisation.oci-containers.containers.caddy-selfsteal = {
    image = "caddy:2-alpine";
    hostname = "caddy-selfsteal";
    extraOptions = [
      "--network=host"
      "--pull=always"
    ];
    environment = {
      SELF_STEAL_DOMAIN = hostConfig.selfstealDomain;
      SELF_STEAL_PORT = "9443";
    };
    volumes = [
      "/opt/selfsteal/Caddyfile:/etc/caddy/Caddyfile:ro"
      "/opt/selfsteal/html:/var/www/html:ro"
      "/opt/selfsteal/logs:/var/log/caddy"
    ];
    autoStart = true;
  };

  # Создание директорий и файлов
  systemd.tmpfiles.rules = [
    "d /opt/selfsteal 0755 root root -"
    "d /opt/selfsteal/html 0755 root root -"
    "d /opt/selfsteal/logs 0755 root root -"
  ];

  # Создание Caddyfile
  environment.etc."selfsteal/Caddyfile" = {
    text = ''
      {
          https_port {$SELF_STEAL_PORT}
          default_bind 127.0.0.1
          servers {
              listener_wrappers {
                  proxy_protocol {
                      allow 127.0.0.1/32
                  }
                  tls
              }
          }
          auto_https disable_redirects
          log {
              output file /var/log/caddy/access.log {
                  roll_size 10MB
                  roll_keep 5
                  roll_keep_for 720h
                  roll_compression gzip
              }
              level ERROR
              format json
          }
      }

      https://{$SELF_STEAL_DOMAIN} {
          root * /var/www/html
          try_files {path} /index.html
          file_server
          log {
              output file /var/log/caddy/access.log {
                  roll_size 10MB
                  roll_keep 5
                  roll_keep_for 720h
                  roll_compression gzip
              }
              level ERROR
          }
      }

      :{$SELF_STEAL_PORT} {
          tls internal
          respond 204
          log off
      }
    '';
    mode = "0644";
  };

  # Создание базового HTML
  environment.etc."selfsteal/html/index.html" = {
    text = ''
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Service Online</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  margin: 0;
                  padding: 40px;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  min-height: 100vh;
                  display: flex;
                  align-items: center;
                  justify-content: center;
                  color: white;
              }
              .container {
                  text-align: center;
                  max-width: 600px;
                  padding: 2rem;
              }
              h1 {
                  font-size: 3rem;
                  margin-bottom: 1rem;
                  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
              }
              p {
                  font-size: 1.2rem;
                  opacity: 0.9;
                  margin-bottom: 2rem;
              }
              .status {
                  background: rgba(255,255,255,0.1);
                  padding: 1rem 2rem;
                  border-radius: 10px;
                  backdrop-filter: blur(10px);
              }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>🚀 Service Ready</h1>
              <p>System is operational and ready to serve</p>
              <div class="status">
                  <p>✅ Status: Online</p>
              </div>
          </div>
      </body>
      </html>
    '';
    mode = "0644";
  };

  # Создание симлинков в /opt/selfsteal
  systemd.services.create-selfsteal-symlinks = {
    description = "Create selfsteal symlinks";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-caddy-selfsteal.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ln -sf /etc/selfsteal/Caddyfile /opt/selfsteal/Caddyfile
      ln -sf /etc/selfsteal/html /opt/selfsteal/html
    '';
  };
}
