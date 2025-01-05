{ pkgs, ... }: {
  imports = [ ./win11.nix ];

  # Основные настройки виртуализации
  boot.kernelModules = [ "kvm-intel" ];

  environment.systemPackages = with pkgs; [
    virtiofsd
    docker
    docker-compose
    lazydocker
  ];

  virtualisation = {
    # Настройки Docker
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      storageDriver = "btrfs"; # Используем btrfs как драйвер хранилища
    };

    # Настройки libvirt
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        swtpm.enable = true;
        verbatimConfig = ''
          virtiofsd="${pkgs.qemu}/libexec/virtiofsd"
        '';
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
    spiceUSBRedirection.enable = true;
  };

  # Дефолтная сеть
  systemd.services.libvirtd-default-network = {
    description = "Enable default libvirt network";
    wantedBy = [ "multi-user.target" ];
    requires = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
    path = [ pkgs.libvirt ];
    script = ''
      if ! virsh net-list --all | grep -q default; then
        virsh net-define ${
          pkgs.writeText "default-network.xml" ''
            <network>
              <name>default</name>
              <forward mode='nat'/>
              <bridge name='virbr0' stp='on' delay='0'/>
              <ip address='192.168.122.1' netmask='255.255.255.0'>
                <dhcp>
                  <range start='192.168.122.2' end='192.168.122.254'/>
                </dhcp>
              </ip>
            </network>
          ''
        }
      fi
      virsh net-autostart default
      virsh net-start default || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
  };

  # Права доступа
  users.users.decard.extraGroups = [ "libvirtd" "kvm" "docker" ];
}
