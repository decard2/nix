{
  pkgs,
  lib,
  ...
}:
{
  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

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

  environment.systemPackages = with pkgs; [
    git
    (writeShellScriptBin "nix_installer" ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🛠️ Начинаю автоматическую установку NixOS..."

      echo "📡 Подключаюсь к WiFi..."
      read -p "Введи имя WiFi сети: " SSID
      read -sp "Введи пароль от WiFi: " PASSWORD
      echo ""

      # Запускаем wpa_supplicant если он не запущен
      sudo systemctl start wpa_supplicant

      # Подключаемся к сети
      wpa_cli -i wlp2s0 <<EOF
        add_network
        set_network 0 ssid "$SSID"
        set_network 0 psk "$PASSWORD"
        enable_network 0
        quit
      EOF

      echo "🌐 Проверяю подключение к интернету..."
      for i in {1..10}; do
        if ping -c 1 ya.ru &>/dev/null; then
          echo "✅ Подключение установлено!"
          break
        fi
        echo "⏳ Жду подключения... ($i/10)"
        sleep 2
        if [ $i -eq 10 ]; then
          echo "❌ Не удалось подключиться к интернету. Выход."
          exit 1
        fi
      done

      echo "💾 Форматирую и монтирую диски..."
      sudo nix \
          --experimental-features 'flakes nix-command' \
          run github:nix-community/disko -- \
          -f github:decard2/nix#emerald \
          -m destroy,format,mount

      echo "📦 Устанавливаю NixOS..."
      sudo nixos-install --flake github:decard2/nix#emerald

      echo "✅ Установка завершена успешно! Перезагружаюсь через 5 секунд..."
      sleep 5
      sudo reboot
    '')
  ];

  # Создаем скрипт, который будет запускаться при старте сессии для пользователя nixos
  system.activationScripts.installerAutostart = ''
    mkdir -p /home/nixos
    cat > /home/nixos/.bash_profile << 'EOF'
    if [[ $(tty) == /dev/tty1 ]]; then
      echo "Запуск установщика NixOS..."
      sleep 2
      exec nix_installer
    fi
    EOF
    chown -R nixos:users /home/nixos
  '';
}
