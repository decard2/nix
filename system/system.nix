{ pkgs, ... }:
{
  system.stateVersion = "24.11";

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

    blacklistedKernelModules = [ "nouveau" ];

    loader = {
      systemd-boot = {
        enable = true;
        # consoleMode = "max";
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
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 30d";
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
    # xserver.videoDrivers = [ "modesetting" ];

    # udev.extraRules = ''
    #   KERNEL=="tun", GROUP="netdev", MODE="0666", OPTIONS+="static_node=net/tun"
    #   SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="*", ATTR{idProduct}=="*", TAG+="uaccess", TAG+="udev-acl"
    #   SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0666"
    # '';

    udisks2.enable = true;

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

    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
      lidSwitchDocked = "suspend";
    };
  };

  # 6. ПОЛЬЗОВАТЕЛИ И ОКРУЖЕНИЕ
  # =========================
  users.users.decard = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
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
    dconf.enable = true;
  };
}
