# Remnanode container configuration module
{
  ...
}:

{
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
  ];

  # Import sync services
  imports = [
    ./sync.nix
  ];

  # Open port for remnanode
  networking.firewall.allowedTCPPorts = [ 2222 ];
}
