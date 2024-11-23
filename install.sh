#!/bin/sh
set -e

# Our cool ASCII art banner
cat << "EOF"

███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

🚀 Let's set up your awesome NixOS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Root privileges required! Run with sudo"
    exit 1
fi

# Check if NixOS
if [ ! -f /etc/NIXOS ]; then
    echo "❌ This is not NixOS! Wrong system"
    exit 1
fi

# WiFi setup function
setup_wifi() {
    echo "📡 Setting up WiFi..."

    # Start wpa_supplicant
    systemctl start wpa_supplicant
    sleep 2

    # Scan networks
    echo "🔍 Searching for networks..."
    iwctl station wlan0 scan
    sleep 2

    # Show networks
    echo "\n📶 Available networks:"
    iwctl station wlan0 get-networks

    # Ask for network name
    printf "\n💭 Enter WiFi name: "
    read -r SSID

    echo "🔌 Connecting to $SSID..."
    iwctl station wlan0 connect "$SSID"

    echo "⏳ Waiting for connection..."
    sleep 5
}

# Check internet
if ! ping -c 1 google.com >/dev/null 2>&1; then
    echo "❌ No internet connection!"
    echo "💡 Let's setup WiFi..."
    setup_wifi

    if ! ping -c 1 google.com >/dev/null 2>&1; then
        echo "❌ Still no internet. Check connection and try again."
        exit 1
    fi
fi

echo "🔧 Installing required tools..."
nix-shell -p git nushell --run "\
    cd /tmp && \
    echo '⚙️  Клонируем конфиги...' && \
    rm -rf ./nix && \
    git clone --depth 1 https://github.com/decard2/nix.git && \
    cd nix && \
    chmod +x setup.nu && \
    nu ./setup.nu
"

echo "
✨ All done!
💡 Reboot and enjoy your new system!
   If something goes wrong - create an issue, we'll help!
"
