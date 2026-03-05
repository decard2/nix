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

  # Network configuration - DHCP for cloud VMs, static for others
  networking.useDHCP = hostConfig.useDHCP or (hostConfig.isGCP or false);

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

  # Kernel sysctl parameters for network optimization
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 7500000;
    "net.core.wmem_max" = 7500000;
    "net.ipv4.ping_group_range" = "0 2000000";
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Users configuration
  users.users.rolder = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDGiqtKA7OrwjvXrF6MdVgIIaxv1JyHybilCsLqNDwaIDMa5r5SUrt6T3efWEIaJj70cIVJwPbgBagGQaWoeg+JkFgndMG2oC1QH5S+GENxThuHB/ON3b+aXtO/BMJDIYHg+AkgV+uSdHrg9F/BDPSTY5he8bwbLAoGWcBTzWxCi4fRisjEBJJPnOAy4SzjbEOdfroLAHPw+XKt16r+c4nAE5zcgPH0eu1sW/52r2pkgiRREXct3c68Gy/uxE7vDhjwn37AidzJ33j4kmStjcUYOCRN9LcG0aOm3kDFx8rVvic0cxeHuYNUZpGyiA3sctQhgw/a74OJtprYvWPAxKqbyK5K6Cq4Hd/vd9ig6e6fWlyqG1kWUvnhEg90KpLxuTaakQaPPqoLKz2TY9gbdB8dHXJF2cKLkqjqPowylgAn5p5KJPaArblYnkoayBDkWxnQnvRA2I4WqRP1/5jY+qjAe9AVT4C+SfGaPf3QOHTrlJUqws+yw9mRPPhk5v7rdTM= roldernet@gmail.com"
    ];
  };

  # SSH - Simple configuration
  services.openssh = {
    enable = true;
    ports = [ 4444 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # QEMU guest agent только для не-облачных ВМ
  services.qemuGuest.enable = !(hostConfig.isGCP or false) && !(hostConfig.useDHCP or false);

  # Basic packages for all hosts
  environment.systemPackages =
    with pkgs;
    [
      git
      curl
      htop
    ]
    ++ lib.optionals (hostConfig.isGCP or false) [
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
