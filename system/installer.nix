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

      echo "🛠️ Starting automated NixOS installation..."

      echo "📡 Connecting to WiFi..."
      read -p "Enter WiFi network name: " SSID
      read -sp "Enter WiFi password: " PASSWORD
      echo ""

      # Determine WiFi interface name
      WIFI_INTERFACE=$(ip link | grep -o 'wl[a-z0-9]*' | head -n 1)
      if [ -z "$WIFI_INTERFACE" ]; then
        echo "❌ Wireless interface not found. Exiting."
        exit 1
      fi
      echo "🔍 Found WiFi interface: $WIFI_INTERFACE"

      # Create temporary configuration file
      WPA_CONF=$(mktemp)
      echo "Creating wpa_supplicant configuration..."
      wpa_passphrase "$SSID" "$PASSWORD" > "$WPA_CONF"

      # Start wpa_supplicant with our configuration
      echo "Starting wpa_supplicant..."
      sudo systemctl start wpa_supplicant
      echo "🔌 Starting WIFI on interface $WIFI_INTERFACE..."
      sudo wpa_supplicant -B -i "$WIFI_INTERFACE" -c "$WPA_CONF"

      # Wait a moment for the system to obtain an IP address automatically
      echo "📡 Waiting for network configuration..."
      sleep 5

      echo "💾 Formatting and mounting disks..."
      sudo nix \
          --experimental-features 'flakes nix-command' \
          run github:nix-community/disko -- \
          -f github:decard2/nix#emerald \
          -m destroy,format,mount

      echo "📦 Installing NixOS..."
      sudo nixos-install --flake github:decard2/nix#emerald

      echo "✅ Installation completed successfully! Rebooting in 5 seconds..."
      sleep 5
      sudo reboot
    '')
  ];

  # Create a script that will run at session start for nixos user
  system.activationScripts.installerAutostart = ''
    cat > /home/nixos/.bash_profile << 'EOF'
    if [[ $(tty) == /dev/tty1 ]]; then
      echo "Starting NixOS installer..."
      sleep 2
      exec nix_installer
    fi
    EOF
  '';
}
