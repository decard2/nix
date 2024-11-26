{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  # Основные настройки системы
  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "24.11";

  # Настройки загрузки
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    extraModulePackages = [
      pkgs.linuxPackages_zen.amneziawg
    ];
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };

    plymouth = {
      enable = true;
      theme = "breeze";
    };

    kernelParams = [
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    initrd.verbose = false;
  };

  # Сеть
  networking = {
    hostName = "emerald";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    dhcpcd.enable = false;
  };

  # Безопасность и права доступа
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=1440
      '';
      extraRules = [
        {
          users = ["decard"];
          commands = [
            {
              command = "/run/current-system/sw/bin/awg-quick";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
  };

  # Сервисы
  services = {
    udev.extraRules = ''
      KERNEL=="tun", GROUP="netdev", MODE="0666", OPTIONS+="static_node=net/tun"
    '';
    udisks2.enable = true;
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "greeter";
        };
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    resolved = {
      enable = true;
      dnssec = "true";
      domains = ["~."];
      fallbackDns = ["1.1.1.1" "8.8.8.8"];
    };
  };

  # Пользователи и окружение
  users.users.decard = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "netdev" "storage"];
    initialPassword = "changeme";
    shell = pkgs.nushell;
  };

  environment = {
    shells = with pkgs; [nushell];
    systemPackages = with pkgs; [
      git
      udiskie
      pamixer
      pavucontrol
      home-manager
      pkgs-unstable.amneziawg-tools
    ];
  };

  # Время
  time.timeZone = "Asia/Irkutsk";

  # Оконный менеджер
  programs.hyprland.enable = true;
}
