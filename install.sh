#!/usr/bin/env bash

# Устанавливаем русскую локаль в лайв-системе
nix-shell -p glibcLocales --run "
  export LOCALE_ARCHIVE=/nix/store/\$(ls -la /nix/store | grep glibc-locales | grep -v drwx | awk '{print \$9}')/lib/locale/locale-archive
  export LANG=ru_RU.UTF-8
  export LC_ALL=ru_RU.UTF-8
"

echo '
╔═══════════════════════════════════════╗
║     Установщик NixOS от Жоры v1.0     ║
║         Сейчас всё будет четко!       ║
╚═══════════════════════════════════════╝
'

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Здорова, братан! Ща всё замутим по красоте!${NC}"

# Проверяем UEFI
if [ ! -d "/sys/firmware/efi" ]; then
    echo -e "${RED}❌ Слышь, а где UEFI? Без него никак!${NC}"
    exit 1
fi

# Спрашиваем про диск
echo -e "${GREEN}💽 Куда ставить будем? Гони название диска (типа /dev/nvme0n1 или /dev/sda)${NC}"
read DISK

# Проверяем существование диска
if [ ! -b "$DISK" ]; then
    echo -e "${RED}❌ Ты чё, братан? Нет такого диска!${NC}"
    exit 1
fi

echo -e "${GREEN}🔄 Щас порежем диск на разделы...${NC}"

# Создаем разделы
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 512MiB 100%

# Форматируем разделы
mkfs.fat -F 32 -n boot "${DISK}1"
mkfs.ext4 -L nixos "${DISK}2"

# Монтируем разделы
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot

echo -e "${GREEN}📦 Тяну конфиг с гитхаба...${NC}"

# Клонируем репозиторий с конфигурацией
nix-shell -p git --run "git clone https://github.com/decard2/nix.git /mnt/etc/nixos"

echo -e "${GREEN}⚙️ Генерю hardware-configuration.nix...${NC}"

# Генерируем hardware-configuration.nix
nixos-generate-config --root /mnt

echo -e "${GREEN}🔨 Погнали ставить систему...${NC}"

# Устанавливаем систему
nixos-install --flake /mnt/etc/nixos#nixos

echo -e "${GREEN}✅ Красота! Система встала! Не забудь сменить пароль после ребута (passwd decard)${NC}"
echo -e "${GREEN}🔄 Можешь ребутаться и логиниться под юзером decard с паролем changeme${NC}"
