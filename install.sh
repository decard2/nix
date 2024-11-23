#!/bin/sh
set -e

# Наша крутая ASCII-арт заставка
cat << "EOF"

███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

🚀 Let's set up your NixOS!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# Проверяем права рута
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Root privileges required! Run with sudo"
    exit 1
fi

# Проверяем что мы в NixOS
if [ ! -f /etc/NIXOS ]; then
    echo "❌ This is not NixOS! Wrong system"
    exit 1
fi

# Генерим русскую локаль
echo "🌍 Generating Russian locale..."
nix-shell -p glibc glibcLocales --run "
    mkdir -p /usr/lib/locale
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
"

# Проверяем получилось ли
if locale -a | grep -q 'ru_RU.utf8'; then
    export LANG=ru_RU.UTF-8
    export LC_ALL=ru_RU.UTF-8
    echo "🎉 Отлично! Переключаемся на русский!"
else
    echo "⚠️  Can't set Russian locale, continuing in English..."
fi

# Функция для настройки WiFi
setup_wifi() {
    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo "📡 Настраиваем WiFi..."
        echo "🔍 Ищем доступные сети..."
    else
        echo "📡 Setting up WiFi..."
        echo "🔍 Searching for networks..."
    fi

    # Запускаем wpa_supplicant
    systemctl start wpa_supplicant
    sleep 2

    # Сканируем сети
    iwctl station wlan0 scan
    sleep 2

    # Показываем список сетей
    echo "\n📶 Available networks:"
    iwctl station wlan0 get-networks

    # Спрашиваем имя сети
    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        printf "\n💭 Введи имя WiFi сети: "
    else
        printf "\n💭 Enter WiFi name: "
    fi
    read -r SSID

    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo "🔌 Подключаемся к $SSID..."
    else
        echo "🔌 Connecting to $SSID..."
    fi
    iwctl station wlan0 connect "$SSID"

    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo "⏳ Ждем подключения..."
    else
        echo "⏳ Waiting for connection..."
    fi
    sleep 5
}

# Проверяем интернет
if ! ping -c 1 google.com >/dev/null 2>&1; then
    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo "❌ Нет интернета!"
        echo "💡 Давай настроим WiFi..."
    else
        echo "❌ No internet connection!"
        echo "💡 Let's setup WiFi..."
    fi
    setup_wifi

    if ! ping -c 1 google.com >/dev/null 2>&1; then
        if [ "$LANG" = "ru_RU.UTF-8" ]; then
            echo "❌ Все равно нет интернета. Проверь подключение и попробуй снова."
        else
            echo "❌ Still no internet. Check connection and try again."
        fi
        exit 1
    fi
fi

# Основная установка
if [ "$LANG" = "ru_RU.UTF-8" ]; then
    echo "🔧 Ставим нужные тулзы..."
else
    echo "🔧 Installing required tools..."
fi

nix-shell -p git nushell --run "\
    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo '📦 Качаем конфиг...'
    else
        echo '📦 Downloading config...'
    fi && \
    git clone https://github.com/decard2/nix /tmp/nixos-config && \
    cd /tmp/nixos-config && \
    if [ "$LANG" = "ru_RU.UTF-8" ]; then
        echo '⚙️  Настраиваем систему...'
    else
        echo '⚙️  Setting up system...'
    fi && \
    ./install.nu
"

if [ "$LANG" = "ru_RU.UTF-8" ]; then
    echo "
✨ Всё готово, братишка!
💡 Перезагрузись и наслаждайся новой системой!
   Если что-то пойдет не так - пиши в issues, поможем!
"
else
    echo "
✨ All done!
💡 Reboot and enjoy your new system!
   If something goes wrong - create an issue, we'll help!
"
fi
