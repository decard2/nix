{ config, pkgs, unstable, hostname, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/desktop
    ../../modules/system
    ../../modules/users
  ];

  boot = {
     loader = {
       systemd-boot = {
         enable = true;
         configurationLimit = 10;  # Храним 10 последних конфигураций
         consoleMode = "max";      # Максимальное разрешение в консоли
         editor = false;           # Отключаем редактирование параметров для безопасности
       };
       efi.canTouchEfiVariables = true;
       timeout = 5;  # Тайм-аут в секундах
     };

     # Plymouth для симпатичной загрузки
     plymouth = {
       enable = true;
       theme = "breeze";  # Можно выбрать другую тему
     };

     # Ставим zen-ядро
       kernelPackages = pkgs.linuxPackages_zen;

       kernelParams = [
         "quiet"
         "splash"
         "rd.systemd.show_status=false"
         "rd.udev.log_level=3"
         "vt.global_cursor_default=0"
         "mitigations=off"      # Отключаем некоторые патчи безопасности для производительности
         "preempt=full"         # Полный пример для десктопа
         "clocksource=tsc"      # Более точный источник времени
         "tsc=reliable"         # Помечаем TSC как надёжный
         "nvidia-drm.modeset=1" # Если используешь NVIDIA
       ];

       kernel.sysctl = {
         # Твики для десктопа
         "vm.swappiness" = 10;                      # Меньше свопим
         "vm.vfs_cache_pressure" = 50;              # Лучше кешируем
         "vm.dirty_background_ratio" = 5;           # Оптимизация записи на диск
         "vm.dirty_ratio" = 10;

         # Сетевые оптимизации
         "net.core.default_qdisc" = "fq";
         "net.ipv4.tcp_congestion_control" = "bbr";
         "net.core.netdev_max_backlog" = 16384;     # Увеличиваем буфер сети
         "net.core.somaxconn" = 8192;

         # Твики для десктопа
         "kernel.sched_autogroup_enabled" = 1;       # Лучшая группировка процессов
         "kernel.sched_cfs_bandwidth_slice_us" = 3000; # Меньше латенси
       };
  };

  # Включаем драйвера NVIDIA
  hardware.nvidia = {
    # Драйвер версии 535 - самый стабильный для MX250
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement = {
    enable = true;
    finegrained = true;  # Более тонкое управление энергопотреблением
    };
    open = true;
    nvidiaSettings = true;

    # Настройки Optimus
    prime = {
    # Intel встроенная
    #intelBusId = "PCI:0:2:0";
    # NVIDIA MX250
    #nvidiaBusId = "PCI:1:0:0";

    # Можно выбрать один из режимов:
    # offload - NVIDIA включается только для конкретных приложений
    # sync - NVIDIA всегда активна (больше энергопотребление)
    # offload.enable = true;  # Рекомендую этот режим для ноута
    sync.enable = true;   # Раскомментируй, если хочешь всегда использовать NVIDIA
    };

    # Переменные окружения для лучшей поддержки
    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        XDG_SESSION_TYPE = "wayland";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";

        # Для запуска приложений на NVIDIA в режиме offload
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

  networking.hostName = hostname;

  environment.systemPackages = with pkgs; [
    firefox

    git
    wget
    curl
    openssh
    kitty # нужен для дефолтного конфига Hyprland
  ];

  nixpkgs.config.allowUnfree = true;
  networking.firewall.enable = true;

  # Добавляем поддержку Electron под Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  system.stateVersion = "24.05";
}
