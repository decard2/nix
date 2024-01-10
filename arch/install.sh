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
echo "###################################"
yes_or_no "Optimizig Pacman mirrorlist?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    sudo pacman -S --noconfirm reflector rsync base-devel wget git
    sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
else
    echo "skip..."
fi

echo "###################################"
yes_or_no "Install YAY? Next steps need it."
echo "###################################"
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
echo "###################################" "Install system packages"
echo "###################################"
yay -S --noconfirm nano btop wget unzip zsh

echo "###################################"
yes_or_no "Disable discrete GPU?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    sudo cp -f ~/nix/configs/etc/modprobe.d/blacklist-nouveau.conf /etc/modprobe.d/blacklist-nouveau.conf
    sudo cp -f ~/nix/configs/etc/udev/rules.d/00-remove-nvidia.rules /etc/udev/rules.d/00-remove-nvidia.rules
else
    echo "skip..."
fi

echo "###################################"
yes_or_no "Install Oh my zsh?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    RUNZSH=no sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
else
    echo "skip..."
fi

# de -----------------------------------
echo "###################################" "Initializing XDG user directories"
echo "###################################"
yay -S --noconfirm git man-db vi xdg-user-dirs
xdg-user-dirs-update

echo "###################################" "Adding $USER to video group"
echo "###################################"
sudo usermod -aG video $USER

echo "###################################"
yes_or_no "Install Hyprland?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm hyprland swaync wl-clipboard cliphist tofi brightnessctl polkit-gnome qt5-wayland qt6-wayland gnome-themes-extra gtk3 ttf-dejavu #wlsunset
else
    echo "skip..."
fi

echo "###################################"
yes_or_no "Install apps? (thunar foot telegram-desktop firefox thorium file-roller shadowsocks)"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm thunar foot telegram-desktop firefox thorium-browser-bin file-roller shadowsocks-rust
else
    echo "skip..."
fi

# dev --------------------------------
echo "###################################"
yes_or_no "Install nvm and Node LTS?"
echo "###################################"
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

echo "###################################"
yes_or_no "Install VSCode?"
echo "###################################"
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
echo "###################################"
yes_or_no "Install devel packages for socket supply?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm webkit2gtk-4.1 clang libc++abi libpthread-stubs at-spi2-core gcc
else
    echo "skip..."
fi

# virt --------------------------------
echo "###################################"
yes_or_no "Install QEMU/KVM virtualization?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm libvirt dnsmasq qemu-desktop virt-manager virt-viewer
    echo "###################################"
    echo "Adding $USER to libvirt group, setup permissions"
    echo "###################################"
    sudo usermod -aG libvirt $USER
    sudo rsync -Ph --recursive ~/nix/configs/etc/libvirt/ /etc/libvirt/

    echo "###################################"
    echo "Enable and start libvirtd.socket"
    echo "###################################"
    sudo systemctl enable libvirtd.socket
    sudo systemctl start libvirtd.socket
    
    echo "###################################"
    echo "Copy vm config and import it to libvirt"
    echo "###################################"
    rsync -Ph --recursive nix/configs/home/vms/ ./vms/
    sudo virsh --connect qemu:///system define ./vms/win2k22.xml

    echo "###################################"
    echo "Start default NAT"
    echo "###################################"
    sudo virsh net-autostart default
    sudo virsh net-start default

    echo "###################################"
    echo "Configuring Virtio-FS to share files"
    echo "###################################"
    sudo rsync -Ph ~/nix/configs/etc/sysctl.d/40-hugepage.conf /etc/sysctl.d/40-hugepage.conf    
else
    echo "skip..."
fi

# defaults
echo "###################################"
yes_or_no "Copy defaults from repo?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    rsync -Ph --recursive nix/configs/home/ .
else
    echo "skip..."
fi

echo "###################################" "Done. You need to reboot."
echo "###################################"
