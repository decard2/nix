{
  pkgs,
  pkgs-unstable,
  config,
  ...
}: {
  # 1. БАЗОВЫЕ НАСТРОЙКИ СИСТЕМЫ
  # ============================
  imports = [
    ./hardware-configuration.nix # Конфигурация железа
    ./disko.nix # Настройки разделов диска
    ./virtualization # Настройки виртуализации
  ];

  system.stateVersion = "24.11"; # Версия системы
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"]; # Включаем флейки

    # Включаем доверенные кеши
    trusted-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];

    # Публичные ключи для проверки
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];

    # Автоматическая оптимизация хранилища
    auto-optimise-store = true;

    # Число параллельных задач при сборке
    max-jobs = "auto";
  };

  # 2. НАСТРОЙКИ ЗАГРУЗЧИКА И ЯДРА
  # =============================
  boot = {
    # Ядро и модули
    kernelPackages = pkgs.linuxPackages_zen; # Используем zen-ядро
    extraModulePackages = [
      pkgs.linuxPackages_zen.amneziawg # Модуль для VPN
    ];

    # Загрузчик systemd-boot
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        editor = false; # Отключаем редактор параметров для безопасности
      };
      efi.canTouchEfiVariables = true;
      timeout = 2; # Тайм-аут меню загрузки
    };

    # Plymouth (загрузочный экран)
    plymouth = {
      enable = true;
      theme = "breeze";
    };

    # Параметры тихой загрузки
    kernelParams = [
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    initrd.verbose = false;
  };

  # 3. УПРАВЛЕНИЕ СИСТЕМОЙ
  # ====================
  nix.gc = {
    automatic = true; # Автоматическая очистка
    dates = "weekly"; # Периодичность
    options = "--delete-older-than 30d"; # Удалять старше 30 дней
  };

  # 4. СЕТЕВЫЕ НАСТРОЙКИ
  # ===================
  networking = {
    hostName = "emerald"; # Имя компьютера
    networkmanager = {
      enable = true;
      wifi.backend = "iwd"; # Используем iwd для WiFi
    };
    dhcpcd.enable = false; # Отключаем dhcpcd в пользу NetworkManager

    extraHosts = ''
      34.234.106.80 kobalte.dev
      100.28.201.155 kobalte.dev
    '';
  };

  # 5. БЕЗОПАСНОСТЬ
  # ==============
  security = {
    rtkit.enable = true; # Планировщик реального времени
    polkit.enable = true; # Система привилегий
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

  # 6. СИСТЕМНЫЕ СЕРВИСЫ
  # ===================
  services = {
    xserver.videoDrivers = ["nvidia"];
    # Правила udev
    udev.extraRules = ''
      KERNEL=="tun", GROUP="netdev", MODE="0666", OPTIONS+="static_node=net/tun"
    '';

    # Управление дисками
    udisks2.enable = true;

    # D-Bus
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };

    # Аудиосистема
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # DNS резолвер
    resolved = {
      enable = true;
      dnssec = "true";
      domains = ["~."];
      fallbackDns = ["1.1.1.1" "8.8.8.8"];
    };

    # Управление питанием
    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
      lidSwitchDocked = "suspend";
    };
  };

  # 7. ПОЛЬЗОВАТЕЛИ И ОКРУЖЕНИЕ
  # =========================
  users.users.decard = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "netdev" "storage"];
    initialPassword = "changeme";
    shell = pkgs.nushell;
  };

  environment = {
    systemPackages = with pkgs; [
      # Основные утилиты
      home-manager
      pkgs-unstable.amneziawg-tools

      # Графические драйверы и утилиты
      intel-media-driver
      libvdpau
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      nvidia-vaapi-driver

      # Добавляем CUDA пакеты
      cudatoolkit
      cudaPackages.cuda_cudart
    ];
  };

  # 8. ЛОКАЛИЗАЦИЯ И ВРЕМЯ
  # ====================
  time.timeZone = "Asia/Irkutsk";

  # Настройки консоли
  console = {
    font = "ter-v32n";
    packages = with pkgs; [terminus_font];
    useXkbConfig = true;
  };

  # Локализация
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "ru_RU.UTF-8";
      LC_IDENTIFICATION = "ru_RU.UTF-8";
      LC_MEASUREMENT = "ru_RU.UTF-8";
      LC_MONETARY = "ru_RU.UTF-8";
      LC_NAME = "ru_RU.UTF-8";
      LC_NUMERIC = "ru_RU.UTF-8";
      LC_PAPER = "ru_RU.UTF-8";
      LC_TELEPHONE = "ru_RU.UTF-8";
      LC_TIME = "ru_RU.UTF-8";
    };
  };

  # 9. ГРАФИЧЕСКОЕ ОКРУЖЕНИЕ
  # ======================
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true; # Поддержка Wayland Session Manager
    };
    dconf.enable = true; # Для некоторых GNOME-приложений
  };

  # 10. СИСТЕМНЫЕ СЛУЖБЫ
  # ==================
  systemd = {
    user.services.hyprpolkitagent = {
      enable = true;
      description = "Hyprland Polkit Agent";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/bin/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        intelBusId = "PCI:0:2:0"; # Для твоей Intel
        nvidiaBusId = "PCI:1:0:0"; # Для твоей NVIDIA
        # Выбери один из режимов:
        # offload = true;  # Для режима по требованию
        sync.enable = true; # Для постоянной работы
      };
    };
    graphics = {
      enable = true;
    };
  };
}
