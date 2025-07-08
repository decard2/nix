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
  networking.firewall.allowedTCPPorts = [
    4444
    2222
    443
  ]; # Custom SSH port + Remnawave

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

  # QEMU Guest agent
  services.qemuGuest.enable = true;

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

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # OCI Containers (Podman) for Remnawave
  virtualisation.oci-containers.backend = "podman";

  # Remnawave Node
  virtualisation.oci-containers.containers.remnanode = {
    image = "remnawave/node:latest";
    hostname = "remnanode";
    extraOptions = [ "--network=host" ];
    environment = {
      APP_PORT = "2222";
      SSL_CERT = "eyJub2RlQ2VydFBlbSI6Ii0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLVxuTUlJQmdEQ0NBU2VnQXdJQkFnSUhBWFVIQTNSRkZUQUtCZ2dxaGtqT1BRUURBakExTVRNd01RWURWUVFERENwUlxuVlRWMU1GRmpXV0pVVW5CVFFWZGZWVTVUWXpOaFEwWmpVVFYyYWpkU09Wa3paSFJ2WVhkeWRGTXdIaGNOTWpVd1xuTmpJek1UZ3pOVFEwV2hjTk1qZ3dOakl6TVRnek5UUTBXakFmTVIwd0d3WURWUVFERXhSWWFraHRRbEJGVkdKNlxuYTA1S1dsbFZlVGhIYURCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhBMElBQkV4WjczTVBwaDQzY0tzdVxuZkQyM01mVVNaY0kyNmRGQ0tIbVdqY3BPMWJvekhzTXdzMEpvQmViTFdqa0UyOHlseTVNdGUyKzMwMkc0SFZTQ1xuVHZURk1XQ2pPREEyTUF3R0ExVWRFd0VCL3dRQ01BQXdEZ1lEVlIwUEFRSC9CQVFEQWdXZ01CWUdBMVVkSlFFQlxuL3dRTU1Bb0dDQ3NHQVFVRkJ3TUJNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJRytsRHIyRGRJdTNBeEl4MUh2Q1xudERhZzVGTDVRNzZ6WXlCTkUrYlFBWkJCQWlBSkpSdlFCeGRBRUJKOWw5bkFpczdnMVZSLzlYa1dMNWdIWng5K1xuaFBZNlBnPT1cbi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0iLCJub2RlS2V5UGVtIjoiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUdIQWdFQU1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhCRzB3YXdJQkFRUWdQMHptVnQ1VERxQnk3cGthXG5Md3AwVjdVaWFOczVQeWZmMFc3R2FxVzFkVVNoUkFOQ0FBUk1XZTl6RDZZZU4zQ3JMbnc5dHpIMUVtWENOdW5SXG5RaWg1bG8zS1R0VzZNeDdETUxOQ2FBWG15MW81Qk52TXBjdVRMWHR2dDlOaHVCMVVnazcweFRGZ1xuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLSIsImNhQ2VydFBlbSI6Ii0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLVxuTUlJQmZEQ0NBU0tnQXdJQkFnSUJBVEFLQmdncWhrak9QUVFEQWpBMU1UTXdNUVlEVlFRRERDcFJWVFYxTUZGalxuV1dKVVVuQlRRVmRmVlU1VFl6TmhRMFpqVVRWMmFqZFNPVmt6WkhSdllYZHlkRk13SGhjTk1qVXdOVEl4TVRNeFxuT1RBNFdoY05NelV3TlRJeE1UTXhPVEE0V2pBMU1UTXdNUVlEVlFRRERDcFJWVFYxTUZGaldXSlVVbkJUUVZkZlxuVlU1VFl6TmhRMFpqVVRWMmFqZFNPVmt6WkhSdllYZHlkRk13V1RBVEJnY3Foa2pPUFFJQkJnZ3Foa2pPUFFNQlxuQndOQ0FBU1ZFRUdaQ1ZsL1hZaDQ4b0NOUHhCTWQ3cG5yTHQrUlcveWxZOHAyMFF2NWZSWkNFTzBrT2ZzQVVCOVxuVS9qZm5SYzBnMGpLMFV2cHRkb3hFbnBrWGVYWW95TXdJVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQTRHQTFVZFxuRHdFQi93UUVBd0lDaERBS0JnZ3Foa2pPUFFRREFnTklBREJGQWlBdFJQYXh5Q1FEazRCRlYxWUZUOHM0dmlmdlxuR0FYRytMbWlRMXBxSndvNjN3SWhBTEFUV2VkY0NPV2pPaFFpRDRzQlQxTWwyWWlnKzI1ZEFuM01jZmpmamI4NlxuLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLSIsImp3dFB1YmxpY0tleSI6Ii0tLS0tQkVHSU4gUFVCTElDIEtFWS0tLS0tXG5NSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXgydDI5OS9MdHg1anlCSEFVczhIXG5QQzNFdldYSGswMUJiZS91cWl4ODJGdnYvbllSYyszQkhRQTNUSllma0kvMnYrZHorN085clBYL2k1ZVJLRnJFXG5VSmNsM2ZWcEh5aGkybGdkR1pyZ0sySEovMkpqenZRU0pXZmQ0c05hUmhjSlM4TXpwQnZkVTNPd1AzRDVWWDd1XG5uMjVPSHZFK3ZHKzBUR3prNUhoNnVod3ozL0RkUklnb0s3S3g0T1MvUExORGVhZlBpLzk3Mnh1TWVsa05yNTdFXG44dWFUQjM0d3dtZ01peDN5VUxnOXdVQ2lIWW4rSFV1TDRBeFRlekU1eGRyZnlwd3JWa2FNY2FWVUNtZnVTdHU5XG5ONE1reTVwRXBXMmJhaDNZNDVOTEhCWTRLeHduMDJDRU80K1IvWSswWVdidit2QndqNFVOQ2NWdmxNdk81M0x1XG51UUlEQVFBQlxuLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tXG4ifQ==";
    };
    autoStart = true;
  };

  # Create Remnawave directory
  systemd.tmpfiles.rules = [
    "d /opt/remnanode 0755 root root -"
  ];

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [ "rolder" ];

  system.stateVersion = "25.05";
}
