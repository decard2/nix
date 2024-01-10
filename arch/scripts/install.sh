#!/usr/bin/bash

if [ "$(id -u)" == 0 ]; then
    echo "Please don't run this script as root"
    exit 1
fi

# Don't continue script if any error occurs.
set -e

function yes_or_no {
    while true; do
        read -r -p "$* [y/n]: " yn
        case $yn in
        [Yy]*)
            choice="Y"
            return 0
            ;;
        [Nn]*)
            choice="n"
            return 0
            ;;
        esac
    done
}

# repos --------------------------------
echo ###################################
echo
yes_or_no "Optimizig Pacman mirrorlist?"
if [ "$choice" == "Y" ]; then
    sudo pacman -S --noconfirm reflector rsync base-devel wget git
    sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
else
    echo "skip..."
fi

echo ###################################
echo
yes_or_no "Install YAY? Next steps need it."
if [ "$choice" == "Y" ]; then
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    yay -Syu --noconfirm
else
    echo "skip..."
fi

# system packages ----------------------
echo ###################################
echo "Install system packages"
yay -S --noconfirm nano btop wget unzip zsh

echo ###################################
echo
yes_or_no "Disable discrete GPU?"
if [ "$choice" == "Y" ]; then
    sudo cp -f ~/nix/configs/etc/modprobe.d/blacklist-nouveau.conf /etc/modprobe.d/blacklist-nouveau.conf
    sudo cp -f ~/nix/configs/etc/udev/rules.d/00-remove-nvidia.rules /etc/udev/rules.d/00-remove-nvidia.rules
else
    echo "skip..."
fi

echo ###################################
echo
yes_or_no "Install Oh my zsh?"
if [ "$choice" == "Y" ]; then
    RUNZSH=no sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
else
    echo "skip..."
fi

# de -----------------------------------
echo ###################################
echo "Initializing XDG user directories"
yay -S --noconfirm git man-db vi xdg-user-dirs
xdg-user-dirs-update

echo ###################################
echo "Adding $USER to video group"
sudo usermod -aG video $USER

echo ###################################
echo
yes_or_no "Install Hyprland?"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm hyprland swaync wl-clipboard cliphist tofi brightnessctl polkit-gnome qt5-wayland qt6-wayland gnome-themes-extra gtk3 ttf-dejavu #wlsunset
else
    echo "skip..."
fi

echo ###################################
echo
yes_or_no "Install apps? (thunar foot telegram-desktop firefox thorium file-roller)"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm thunar foot telegram-desktop firefox thorium-browser-bin file-roller
else
    echo "skip..."
fi

# dev --------------------------------
echo ###################################
echo
yes_or_no "Install nvm and Node LTS?"
if [ "$choice" == "Y" ]; then
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install --lts
else
    echo "skip..."
fi

# VSCode

# overload on first load

echo ###################################
echo
yes_or_no "Install VSCode?"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm visual-studio-code-bin
    code --install-extension yzhang.markdown-all-in-one
    code --install-extension foxundermoon.shell-format
    echo "Setup git"
    git config --global user.name "Decard"
    git config --global user.email "mail@dayreon.ru"
else
    echo "skip..."
fi

# Sucket supply
echo ###################################
echo
yes_or_no "Install devel packages for socket supply?"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm webkit2gtk-4.1 clang libc++abi libpthread-stubs at-spi2-core gcc
else
    echo "skip..."
fi

# virt --------------------------------
echo ###################################
echo
yes_or_no "Install QEMU/KVM virtualization?"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm libvirt dnsmasq qemu-desktop virt-manager virt-viewer
    echo ###################################
    echo "Adding $USER to libvirt group, setup permissions"
    sudo usermod -aG libvirt $USER
    sudo rsync -Ph --recursive ~/nix/configs/etc/libvirt/ /etc/libvirt/

    echo ###################################
    echo "Create vms folder, disable btrfs copy-on-write on it"
    mkdir ~/vms
    chattr +C ~/vms

    echo ###################################
    echo "Enable and start libvirtd.socket"
    sudo systemctl enable libvirtd.socket
    sudo systemctl start libvirtd.socket
    
    echo ###################################
    echo "Copy vm config and import it to libvirt"
    rsync -Ph --recursive nix/configs/home/vms/ ./vms/
    sudo virsh --connect qemu:///system define ./vms/win2k22.xml

    echo ###################################
    echo "Start default NAT"
    sudo virsh net-autostart default
    sudo virsh net-start default

    echo ###################################
    echo "Configuring Virtio-FS to share files"
    sudo rsync -Ph ~/nix/configs/etc/sysctl.d/40-hugepage.conf /etc/sysctl.d/40-hugepage.conf

    echo ###################################
    echo "Add suspend when host reboots or shutdowns"    
else
    echo "skip..."
fi

# defaults
echo ###################################
echo
yes_or_no "Copy defaults from repo?"
if [ "$choice" == "Y" ]; then
    rsync -Ph --recursive nix/configs/home/ .
else
    echo "skip..."
fi

echo ###################################
echo "Done. You need to reboot."
