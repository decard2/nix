# Remnawave Panel container configuration module
{
  pkgs,
  ...
}:

{
  # Create Remnawave directories
  systemd.tmpfiles.rules = [
    "d /opt/remnawave 0755 root root -"
    "d /opt/remnawave/postgres_data 0755 root root -"
    "d /opt/remnawave/redis_data 0755 999 999 -"
    "d /opt/remnawave/caddy_data 0755 root root -"
    "d /opt/remnawave/caddy_config 0755 root root -"
    "L /opt/remnawave/Caddyfile - - - - /etc/Caddyfile"
  ];

  # Create network for containers
  systemd.services.create-remnawave-network = {
    description = "Create remnawave network";
    after = [ "podman.service" ];
    before = [
      "podman-remnawave-db.service"
      "podman-remnawave-redis.service"
      "podman-remnawave-backend.service"
      "podman-caddy.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman network exists remnawave-net || ${pkgs.podman}/bin/podman network create remnawave-net
    '';
  };

  # PostgreSQL container for Remnawave Panel
  virtualisation.oci-containers.containers.remnawave-db = {
    image = "postgres:17";
    ports = [
      "127.0.0.1:6767:5432"
    ];
    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_PASSWORD = "4362a038f7ffb24c578961ecbb0ab2861d87ef6cd029eac6";
      POSTGRES_DB = "remnawave";
      TZ = "UTC";
    };
    volumes = [
      "/opt/remnawave/postgres_data:/var/lib/postgresql/data"
    ];
    extraOptions = [
      "--network=remnawave-net"
      "--pull=always"
    ];
    autoStart = true;
  };

  # Valkey (Redis) container for Remnawave Panel
  virtualisation.oci-containers.containers.remnawave-redis = {
    image = "valkey/valkey:8.0.2-alpine";
    volumes = [
      "/opt/remnawave/redis_data:/data"
    ];
    cmd = [
      "valkey-server"
      "--appendonly"
      "yes"
      "--appendfsync"
      "everysec"
      "--save"
      "900 1"
      "--save"
      "300 10"
      "--save"
      "60 10000"
      "--dir"
      "/data"
    ];
    extraOptions = [
      "--network=remnawave-net"
      "--pull=always"
    ];
    autoStart = true;
  };

  # Remnawave Backend container
  virtualisation.oci-containers.containers.remnawave-backend = {
    image = "remnawave/backend:latest";
    ports = [
      "127.0.0.1:3000:3000"
    ];
    environment = {
      # Database configuration
      POSTGRES_USER = "postgres";
      POSTGRES_PASSWORD = "4362a038f7ffb24c578961ecbb0ab2861d87ef6cd029eac6";
      POSTGRES_DB = "remnawave";
      DATABASE_URL = "postgresql://postgres:4362a038f7ffb24c578961ecbb0ab2861d87ef6cd029eac6@remnawave-db:5432/remnawave";

      # Redis configuration
      REDIS_HOST = "remnawave-redis";
      REDIS_PORT = "6379";

      # JWT secrets
      JWT_AUTH_SECRET = "39ecf71fc8848836778d418eda3d0402594adb66f1202e514fb8e79a8137fb9d5d0c50e97655582d1c46de226a666c7717375559f5d79217c2f70dcf9dadc449";
      JWT_API_TOKENS_SECRET = "17c25c69a9523535c8f20db5fb17343a165ecf109244cc363231410ba2407802ed9748652c239b7a5f1936a54be411063b1165575a4bb9362a5851e1afc64842";

      # Panel configuration
      FRONT_END_DOMAIN = "rolder.net";
      SUB_PUBLIC_DOMAIN = "rolder.net/api/sub";

      # API
      IS_DOCS_ENABLED = "true";
      SWAGGER_PATH = "/swagger";
      SCALAR_PATH = "/scalar";

      # Metrics configuration
      METRICS_USER = "admin";
      METRICS_PASS = "e7a6c24feaff3ae79b40d3d253c0e8fcecf2252cd1a2669292c83ee89f2d93423b8e53f48df8b3ff7fa4d437e34b117cff1cd437bc6677bbb10f5e681658e343";

      # Webhook configuration
      WEBHOOK_SECRET_HEADER = "29ca08a3c94d183a7519e3b46fdbec1a5977f64d4322971d1983c7ca23d82a3615b4423960d36bd8dd93bd1fc8bf59ccd3480bc01b37c277b69638a3e7209efc";
      WEBHOOK_URL = "https://rolder.net/wh";

      # Telegram
      IS_TELEGRAM_NOTIFICATIONS_ENABLED = "false";
      TELEGRAM_OAUTH_ENABLED = "false";

      # App configuration
      NODE_ENV = "production";
      TZ = "UTC";
    };
    volumes = [
      "/opt/remnawave:/app/data"
    ];
    extraOptions = [
      "--network=remnawave-net"
      # "--pull=always"
    ];
    autoStart = true;
  };

  # Caddy reverse proxy container
  virtualisation.oci-containers.containers.caddy = {
    image = "caddy:2-alpine";
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/opt/remnawave/Caddyfile:/etc/caddy/Caddyfile:ro"
      "/opt/remnawave/caddy_data:/data"
      "/opt/remnawave/caddy_config:/config"
    ];
    dependsOn = [
      "remnawave-backend"
      "remnawave-db"
      "remnawave-redis"
    ];
    extraOptions = [
      "--network=remnawave-net"
      "--pull=always"
    ];
    autoStart = true;
  };

  # Create Caddy configuration file
  environment.etc."Caddyfile" = {
    text = ''
      # Global options
      {
        # Email for Let's Encrypt notifications
        email mail@rolder.dev

        # Use Let's Encrypt production environment
        acme_ca https://acme-v02.api.letsencrypt.org/directory

        # Enable admin API (optional, for management)
        admin off

        # Optimize for performance
        servers {
          protocols h1 h2
        }
      }

      # Main site configuration
      rolder.net {
        # Reverse proxy to backend
        reverse_proxy remnawave-backend:3000 {
          # Health check
          health_uri /health
          health_interval 30s
          health_timeout 5s

          # Headers for proper proxying
          header_up Host {upstream_hostport}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }

        # Security headers
        header {
          # Remove server information
          -Server

          # Security headers
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          X-XSS-Protection "1; mode=block"
          Referrer-Policy "strict-origin-when-cross-origin"

          # CSP (adjust as needed for your application)
          Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' wss: ws:;"
        }

        # Enable compression (automatic)
        encode gzip zstd

        # Logging (optional)
        log {
          output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
          }
          format json
        }
      }

      # Catch-all for other domains (security)
      :443 {
        respond "Not Found" 404
      }

      # HTTP redirect (automatic)
      :80 {
        redir https://{host}{uri} permanent
      }
    '';
    mode = "0644";
  };

  # Import sync services
  imports = [
    ./sync.nix
  ];
}
