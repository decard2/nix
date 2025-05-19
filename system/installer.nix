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

      # Определяем имя WiFi интерфейса
      WIFI_INTERFACE=$(ip link | grep -o 'wl[a-z0-9]*' | head -n 1)
      if [ -z "$WIFI_INTERFACE" ]; then
        echo "❌ Не найден беспроводной интерфейс. Выход."
        exit 1
      fi
      echo "🔍 Найден WiFi интерфейс: $WIFI_INTERFACE"
      
      # Создаем временный конфигурационный файл
      WPA_CONF=$(mktemp)
      wpa_passphrase "$SSID" "$PASSWORD" > "$WPA_CONF"
      
      # Останавливаем любые существующие экземпляры wpa_supplicant
      sudo systemctl stop wpa_supplicant 2>/dev/null || true
      sudo killall wpa_supplicant 2>/dev/null || true
      
      # Запускаем wpa_supplicant с нашей конфигурацией
      sudo ip link set "$WIFI_INTERFACE" up
      echo "🔌 Запуск wpa_supplicant на интерфейсе $WIFI_INTERFACE..."
      sudo wpa_supplicant -B -i "$WIFI_INTERFACE" -c "$WPA_CONF"
      
      # Получаем IP-адрес через DHCP
      echo "📡 Получение IP-адреса..."
      sudo dhclient -v "$WIFI_INTERFACE"

      echo "🌐 Проверяю подключение к интернету..."
      for i in {1..15}; do
        if ping -c 1 8.8.8.8 &>/dev/null; then
          echo "✅ Подключение к интернету установлено!"
          # Очистка временного файла
          rm -f "$WPA_CONF"
          break
        fi
        echo "⏳ Жду подключения... ($i/15)"
        sleep 2
        if [ $i -eq 15 ]; then
          echo "❌ Не удалось подключиться к интернету. Выход."
          # Диагностическая информация
          echo "📊 Диагностическая информация:"
          ip addr show "$WIFI_INTERFACE"
          sudo wpa_cli -i "$WIFI_INTERFACE" status
          rm -f "$WPA_CONF"
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
