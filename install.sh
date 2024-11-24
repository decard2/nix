#!/usr/bin/env bash

echo '
====================================
   NixOS Installer by Zhora v1.0-3
   Let'"'"'s make it smooth, bro!
===================================='

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Yo, wassup! Let's get this party started!${NC}"

# Check for UEFI
test -d "/sys/firmware/efi"
UEFI_CHECK=$?

if [ $UEFI_CHECK -ne 0 ]; then
    echo -e "${RED}❌ Bruh, where's UEFI? Can't roll without it!${NC}"
    exit 1
fi

# Ask for disk
echo -e "${GREEN}💽 Which disk we're hitting? Drop the name (like /dev/nvme0n1 or /dev/sda)${NC}"
read DISK

# Check if disk exists
if [ ! -b "$DISK" ]; then
    echo -e "${RED}❌ Nah fam, that disk doesn't exist!${NC}"
    exit 1
fi

echo -e "${GREEN}🔄 Slicing up that disk real quick...${NC}"

# Create partitions
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart primary 512MiB 100%

# Format partitions
mkfs.fat -F 32 -n boot "${DISK}1"
mkfs.ext4 -L nixos "${DISK}2"

# Mount partitions
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot

echo -e "${GREEN}📦 Pulling config from GitHub...${NC}"

# Clone configuration repository
nix-shell -p git --run "git clone https://github.com/decard2/nix.git /mnt/etc/nixos"

echo -e "${GREEN}⚙️ Generating hardware-configuration.nix...${NC}"

# Generate hardware-configuration.nix
nixos-generate-config --root /mnt

echo -e "${GREEN}🔨 Time to install this bad boy...${NC}"

# Install the system
nixos-install --flake /mnt/etc/nixos#nixos

echo -e "${GREEN}✅ Sweet! All done! Don't forget to change your password after reboot (passwd decard)${NC}"
echo -e "${GREEN}🔄 You can reboot now and login as decard with password 'changeme'${NC}"
