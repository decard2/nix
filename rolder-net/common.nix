# Common base configuration for all hosts
# This module contains shared settings that apply to all servers
{
  pkgs,
  lib,
  hostConfig,
  ...
}:

let
  # API token for Remnawave panel
  remnawave_api_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiYTg1YjZkMDEtOTUyNS00Mjg3LTk3ZDYtMmVkZjg4ZWVlYTZiIiwidXNlcm5hbWUiOm51bGwsInJvbGUiOiJBUEkiLCJpYXQiOjE3NTE5OTI0ODcsImV4cCI6MTAzOTE5MDYwODd9.xRzDMZ7iInTXWK_cJtSM74hdC1wmkHYmlSAsO3q0MRc";
in

{
  imports = [
    ./hardware-common.nix
  ]
  ++ (map (container: ./containers/${container}.nix) hostConfig.containers);

  # Pass API token to all containers
  _module.args.remnawave_api_token = remnawave_api_token;

  # Network configuration
  networking.hostName = hostConfig.hostname;

  # Network configuration - DHCP for GCP, static for others
  networking.useDHCP = hostConfig.isGCP or false;

  # Static IP configuration for non-GCP servers
  networking.interfaces = lib.mkIf (!(hostConfig.isGCP or false) && (hostConfig ? serverIP)) {
    ens3 = {
      ipv4.addresses = [
        {
          address = hostConfig.serverIP;
          prefixLength = 24;
        }
      ];
    };
  };

  # Default gateway for non-GCP servers
  networking.defaultGateway = lib.mkIf (!(hostConfig.isGCP or false) && (hostConfig ? gateway)) {
    address = hostConfig.gateway;
    interface = "ens3";
  };

  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Firewall configuration
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    2222 # Remna
    4444 # Custom SSH port
    443 # HTTPS
  ];

  # Time zone
  # time.timeZone = "Europe/Moscow";

  # Users configuration
  users.users.rolder = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    hashedPassword = hostConfig.rolderPassword;
  };

  # SSH - Simple configuration
  services.openssh = {
    enable = true;
    ports = [ 4444 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };

  # Guest agent - different for GCP and regular VMs
  services.qemuGuest.enable = !(hostConfig.isGCP or false);

  # Basic packages for all hosts
  environment.systemPackages =
    with pkgs;
    [
      git
      curl
      htop
    ]
    ++ lib.optionals (hostConfig.isGCP or false) [
      # Google Cloud guest environment for GCP instances
      google-guest-agent
      google-guest-configs
    ];

  # Enable containers support
  virtualisation.containers.enable = true;

  # OCI Containers backend
  virtualisation.oci-containers.backend = "podman";

  # Podman configuration
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # Docker registry mirrors
    dockerCompat = true;
  };

  # Container registry configuration
  environment.etc."containers/registries.conf" = lib.mkForce {
    text = ''
      unqualified-search-registries = ["docker.io", "quay.io"]

      [[registry]]
      location = "docker.io"

      [[registry.mirror]]
      location = "mirror.gcr.io"

      [[registry.mirror]]
      location = "registry.dockermirror.com"

      [[registry.mirror]]
      location = "docker.m.daocloud.io"
    '';
  };

  # Enable flakes and trusted users
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ "rolder" ];

  # System version
  system.stateVersion = "25.05";
}
