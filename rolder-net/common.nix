# Common base configuration for all hosts
# This module contains shared settings that apply to all servers
{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}:

{
  imports = [
    ./hardware-common.nix
  ] ++ (map (container: ./containers/${container}.nix) hostConfig.containers);

  # Network configuration
  networking.hostName = hostConfig.hostname;
  networking.interfaces.ens3 = {
    ipv4.addresses = [
      {
        address = hostConfig.serverIP;
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = hostConfig.gateway;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Firewall configuration
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    4444 # Custom SSH port
    443 # HTTPS
  ];

  # Time zone
  time.timeZone = "Europe/Moscow";

  # Users configuration
  users.users.rolder = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    hashedPassword = hostConfig.rolderPassword;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here if needed
    ];
  };

  # SSH - Enhanced Security
  services.openssh = {
    enable = true;
    ports = [ 4444 ]; # Custom SSH port
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      AllowUsers = [ "rolder" ];
    };
  };

  # QEMU Guest agent for all VMs
  services.qemuGuest.enable = true;

  # Basic packages for all hosts
  environment.systemPackages = with pkgs; [
    git
    curl
    htop
    docker-compose
  ];

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
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
