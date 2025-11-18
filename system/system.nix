{ pkgs, ... }:
{
  system.stateVersion = "25.05";

  # 1. БАЗОВЫЕ НАСТРОЙКИ СИСТЕМЫ
  # ============================
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [ "decard" ];

    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://cache.flox.dev"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];

    auto-optimise-store = true;
    max-jobs = "auto";
  };

  # 2. НАСТРОЙКИ ЗАГРУЗЧИКА И ЯДРА
  # =============================
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;

    # extraModprobeConfig = ''
    #   blacklist nouveau
    #   options nouveau modeset=0
    # '';

    # blacklistedKernelModules = [
    #   "nouveau"
    #   "nvidia"
    #   "nvidia_drm"
    #   "nvidia_modeset"
    # ];

    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };

    plymouth = {
      enable = true;
      theme = "flame";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override { selected_themes = [ "flame" ]; })
      ];
    };

    kernelParams = [
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr3";
      "net.core.default_qdisc" = "fq";
    };

    initrd.verbose = false;
  };

  # 3. УПРАВЛЕНИЕ СИСТЕМОЙ
  # ====================
  nix.gc = {
    automatic = true;
    dates = "daily";
    persistent = true;
    options = "--delete-older-than 10d";
  };

  # 4. БЕЗОПАСНОСТЬ
  # ==============
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=1440
      '';
    };
  };

  # 5. СИСТЕМНЫЕ СЕРВИСЫ
  # ===================
  services = {
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    logind.settings.Login = {
      HandleLidSwitchDocked = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitch = "suspend";
    };

    # udev.extraRules = ''
    #   # Remove NVIDIA USB xHCI Host Controller devices, if present
    #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    #   # Remove NVIDIA USB Type-C UCSI devices, if present
    #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    #   # Remove NVIDIA Audio devices, if present
    #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    #   # Remove NVIDIA VGA/3D controller devices
    #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
    # '';
  };

  # 6. ПОЛЬЗОВАТЕЛИ И ОКРУЖЕНИЕ
  # =========================
  users.users.decard = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "netdev"
      "storage"
      "plugdev"
    ];
    initialPassword = "changeme";
    shell = pkgs.fish;
  };

  # 7. ЛОКАЛИЗАЦИЯ И ВРЕМЯ
  # ====================
  time.timeZone = "Asia/Irkutsk";

  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    useXkbConfig = true;
  };

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

  # 8. ГРАФИЧЕСКОЕ ОКРУЖЕНИЕ и системные программы
  # ======================
  programs = {
    fish.enable = true;
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    regreet = {
      enable = true;
      settings.GTK = {
        application_prefer_dark_theme = true;
      };
    };
    dconf.enable = true;
  };

  hardware.graphics = {
    enable = true;
    # extraPackages = with pkgs; [
    #   intel-media-driver
    # ];
  };
  services.xserver.videoDrivers = [
    "nvidia"
    "modesetting"
  ];
  hardware.nvidia.open = false;
  hardware.nvidia.prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/Hyprland --config ${pkgs.writeText "hyprland-greeter.conf" ''
          # Автоопределение всех мониторов
          monitor=,preferred,auto,1

          # Запускаем ReGreet
          exec-once = ${pkgs.regreet}/bin/regreet; hyprctl dispatch exit

          # Дополнительные настройки Hyprland для ReGreet
          misc {
            disable_hyprland_logo = true
            disable_splash_rendering = true
            disable_hyprland_guiutils_check = true
          }

          # Отключаем порталы для ускорения запуска
          env = GTK_USE_PORTAL,0
          env = GDK_DEBUG,no-portals
        ''}";
        user = "greeter";
      };
    };
  };
}
