{
  pkgs,
  hostname,
  rolderPassword,
  serverIP,
  gateway,
  modulesPath,
  ...
}:

{
  imports = [
    ./hardware/${hostname}.nix
    # KVM/QEMU guest profile for all VMs
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot loader - GRUB for BIOS Legacy boot only
  boot.loader.grub.enable = true;
  # Let disko handle device configuration

  # Console configuration for VirtIO
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
    "earlyprintk=ttyS0,115200"
    "consoleblank=0"
  ];

  # Network
  networking.hostName = hostname;
  networking.interfaces.ens3 = {
    ipv4.addresses = [
      {
        address = serverIP;
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = gateway;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 4444 ]; # Custom SSH port

  # Time zone
  time.timeZone = "Europe/Moscow";

  # Users
  users.users.rolder = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    hashedPassword = rolderPassword;
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

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    curl
    htop
    docker-compose
  ];

  # Common VM/KVM settings
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "sr_mod"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "virtio_net"
    "virtio_ring"
  ];

  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_rng"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "25.05";
}
