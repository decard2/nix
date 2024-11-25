{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "tun" ];



    # Настраиваем загрузчик systemd-boot
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";        # Максимальное разрешение в меню загрузки
        editor = false;             # Отключаем возможность редактирования параметров (безопасность)
      };
      efi.canTouchEfiVariables = true;
      timeout = 2;                  # Тайм-аут в секундах
    };

    # Настраиваем Plymouth
    plymouth = {
      enable = true;
      theme = "breeze";            # Можно выбрать другие темы
    };

    # Параметры ядра для тихой загрузки
    kernelParams = [
      "quiet"                      # Убираем большинство сообщений ядра
      "splash"                     # Включаем сплэш
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"       # Уменьшаем уровень логирования
      "udev.log_priority=3"
    ];



    # Убираем задержку при загрузке
    initrd.verbose = false;
    initrd.availableKernelModules = [ "virtio_gpu" "virtio_pci" ];
  };

  # Разрешаем создание TUN/TAP интерфейсов
  security.wrappers = {
    tun = {
      source = "${pkgs.iproute2}/bin/ip";
      capabilities = "cap_net_admin+ep";
      owner = "root";  # Добавляем владельца
      group = "netdev";  # И группу
      permissions = "u+rx,g+rx";  # Права доступа
    };
  };

  environment.shells = with pkgs; [ nushell ];

  networking = {
    hostName = "emerald";
  };

  time.timeZone = "Asia/Irkutsk";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  virtualisation.libvirtd.enable = true;
  services.qemuGuest.enable = true;  # Включает QEMU guest tools
  services.spice-vdagentd.enable = true;  # Включает SPICE agent
  systemd.services.spice-vdagentd.enable = true;
  systemd.services.qemu-guest-agent.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.decard = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "netdev"];
    initialPassword = "changeme";
    shell = pkgs.nushell;
  };

  environment.systemPackages = with pkgs; [
    git
    vulkan-tools
    vulkan-validation-layers
    mesa
    spice-vdagent
    spice-protocol
    dnsutils
  ];

  programs.hyprland.enable = true;
  security.polkit.enable = true;

  system.stateVersion = "24.05";
}
