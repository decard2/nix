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
echo "Install system packages"
echo "###################################"
yay -S --noconfirm nano btop wget unzip zsh acpid snapper btrfs-assistant
sudo systemctl enable acpid
sudo systemctl start acpid
sudo chmod 666 /sys/power/state
sudo cp ~/nix/configs/etc/sysctl.d/disable_watchdog.conf /etc/sysctl.d/

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
    git clone --depth=1 https://github.com/ntnyq/omz-plugin-pnpm.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm
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
    yay -S --noconfirm hyprland xdg-desktop-portal-wlr hyprcursor-dracula-kde-git dracula-icons-theme swaync wl-clipboard cliphist tofi brightnessctl polkit-gnome qt5-wayland qt6-wayland gnome-themes-extra gtk3 ttf-dejavu wlsunset
else
    echo "skip..."
fi

echo "###################################"
yes_or_no "Install apps? (thunar foot telegram-desktop firefox thorium file-roller)"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm thunar foot telegram-desktop firefox thorium-browser-bin file-roller
else
    echo "skip..."
fi

echo "###################################"
yes_or_no "Install shadowsocks?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm shadowsocks-rust
else
    echo "skip..."
fi

# dev --------------------------------
echo "###################################"
yes_or_no "Install nvm, Node lts and pnpm?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install --lts
    wget -qO- https://get.pnpm.io/install.sh | sh -
else
    echo "skip..."
fi

# VSCode
echo "###################################"
yes_or_no "Install VSCode?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm visual-studio-code-bin
    code --install-extension foxundermoon.shell-format
    code --install-extension esbenp.prettier-vscode
    echo "Setup git"
    git config --global user.name "Decard"
    git config --global user.email "mail@dayreon.ru"
else
    echo "skip..."
fi

# devops --------------------------------
# kubernetes
echo "###################################"
yes_or_no "Install kubectl and helm?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm kubectl helm
else
    echo "skip..."
fi

# s3cmd
echo "###################################"
yes_or_no "Install s3cmd?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    yay -S --noconfirm s3cmd
else
    echo "skip..."
fi

# yandex cli
echo "###################################"
yes_or_no "Install Ynadex CLI?"
echo "###################################"
if [ "$choice" == "Y" ]; then
    curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
else
    echo "skip..."
fi

# virt ----------------------------------
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
    sudo virsh --connect qemu:///system define ./vms/win10.xml

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
    sudo rsync -Ph --recursive nix/configs/etc/ /etc/
else
    echo "skip..."
fi

echo "###################################" "Done. You need to reboot."
echo "###################################"
