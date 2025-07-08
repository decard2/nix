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
    "L /opt/remnawave/angie.conf - - - - /etc/angie.conf"
  ];

  # Create network for containers
  systemd.services.create-remnawave-network = {
    description = "Create remnawave network";
    after = [ "podman.service" ];
    before = [
      "podman-remnawave-db.service"
      "podman-remnawave-redis.service"
      "podman-remnawave-backend.service"
      "podman-remnawave-angie.service"
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

  # Create Docker volume for SSL certificates
  systemd.services.create-angie-ssl-volume = {
    description = "Create angie SSL volume";
    after = [ "podman.service" ];
    before = [ "podman-remnawave-angie.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.podman}/bin/podman volume exists angie-ssl-data || ${pkgs.podman}/bin/podman volume create angie-ssl-data
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
    ];
    autoStart = true;
  };

  # Angie reverse proxy container
  virtualisation.oci-containers.containers.remnawave-angie = {
    image = "docker.angie.software/angie:latest";
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "/opt/remnawave/angie.conf:/etc/angie/http.d/default.conf:ro"
      "angie-ssl-data:/var/lib/angie/acme/"
    ];
    dependsOn = [
      "remnawave-backend"
      "remnawave-db"
      "remnawave-redis"
    ];
    extraOptions = [
      "--network=remnawave-net"
    ];
    autoStart = true;
  };

  # Create Angie configuration file
  environment.etc."angie.conf" = {
    text = ''
      upstream remnawave {
          server remnawave-backend:3000;
      }

      # Connection header for WebSocket reverse proxy
      map $http_upgrade $connection_upgrade {
          default upgrade;
          "" close;
      }

      resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220;

      acme_client acme_le https://acme-v02.api.letsencrypt.org/directory;

      server {
          server_name rolder.net;

          listen 443 ssl reuseport;
          listen [::]:443 ssl reuseport;
          http2 on;

          acme acme_le;

          # SSL Configuration (Mozilla Intermediate)
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
          ssl_session_timeout 1d;
          ssl_session_cache shared:SSL:1m;
          ssl_session_tickets off;
          ssl_certificate $acme_cert_acme_le;
          ssl_certificate_key $acme_cert_key_acme_le;

          location / {
              proxy_http_version 1.1;
              proxy_pass http://remnawave;
              proxy_set_header Host $host;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection $connection_upgrade;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
          }

          # Gzip Compression
          gzip on;
          gzip_vary on;
          gzip_proxied any;
          gzip_comp_level 6;
          gzip_buffers 16 8k;
          gzip_http_version 1.1;
          gzip_min_length 256;
          gzip_types
              application/atom+xml
              application/geo+json
              application/javascript
              application/x-javascript
              application/json
              application/ld+json
              application/manifest+json
              application/rdf+xml
              application/rss+xml
              application/xhtml+xml
              application/xml
              font/eot
              font/otf
              font/ttf
              image/svg+xml
              text/css
              text/javascript
              text/plain
              text/xml;
      }

      server {
          listen 443 ssl default_server;
          listen [::]:443 ssl default_server;
          server_name _;

          ssl_reject_handshake on;
      }

      server {
          listen 80;
          return 444; # https://angie.software/angie/docs/configuration/acme/#http
      }
    '';
    mode = "0644";
  };

  # Import sync services
  imports = [
    ./sync.nix
  ];
}
