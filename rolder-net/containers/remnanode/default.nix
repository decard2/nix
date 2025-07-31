# Remnanode container configuration module
{
  hostConfig,
  ...
}:

{
  # Caddy reverse proxy container for Reality Self Steal
  virtualisation.oci-containers.containers.caddy-node = {
    image = "caddy:2-alpine";
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/opt/remnanode/Caddyfile:/etc/caddy/Caddyfile:ro"
      "/opt/remnanode/caddy_data:/data"
      "/opt/remnanode/caddy_config:/config"
      "/opt/remnanode/www:/srv"
    ];
    extraOptions = [
      "--network=host"
      "--pull=always"
    ];
    autoStart = true;
  };

  # Remnawave Node container
  virtualisation.oci-containers.containers.remnanode = {
    image = "remnawave/node:latest";
    hostname = "remnanode";
    extraOptions = [
      "--network=host"
      "--pull=always"
    ];
    environment = {
      APP_PORT = "2222";
    };
    environmentFiles = [
      "/opt/remnanode/node-certificate.env"
    ];
    volumes = [
      "/opt/remnanode:/opt/remnanode"
    ];
    autoStart = true;
  };

  # Create Remnawave directories
  systemd.tmpfiles.rules = [
    "d /opt/remnanode 0755 root root -"
    "d /opt/remnanode/caddy_data 0755 root root -"
    "d /opt/remnanode/caddy_config 0755 root root -"
    "d /opt/remnanode/www 0755 root root -"
    "L /opt/remnanode/Caddyfile - - - - /etc/caddy-node/Caddyfile"
  ];

  # Create Caddy configuration for Reality Self Steal
  environment.etc."caddy-node/Caddyfile" = {
    text = ''
      {
        https_port 4123
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
      }

      https://${hostConfig.nodeDomain} {
        root * /srv
        file_server
      }

      http://${hostConfig.nodeDomain} {
        bind 0.0.0.0
        redir https://${hostConfig.nodeDomain}{uri} permanent
      }

      :4123 {
        tls internal
        respond 204
      }

      :80 {
        bind 0.0.0.0
        respond 204
      }
    '';
    mode = "0644";
  };

  # Create simple HTML page for masking
  environment.etc."remnanode-www/index.html" = {
    text = ''
      <!DOCTYPE html>
      <html>
      <head>
          <title>Welcome</title>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
      </head>
      <body>
          <h1>Welcome to our service</h1>
          <p>This is a simple web service.</p>
      </body>
      </html>
    '';
    mode = "0644";
  };

  # Copy HTML to node directory
  systemd.services.setup-node-www = {
    description = "Setup node www directory";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      cp /etc/remnanode-www/index.html /opt/remnanode/www/
    '';
  };

  # Import sync services
  imports = [
    # ./sync.nix
  ];

  # Open ports for remnanode and Caddy
  networking.firewall.allowedTCPPorts = [
    80
    443
    2222
  ];
}
