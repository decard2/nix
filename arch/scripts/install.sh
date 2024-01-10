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

echo "Optimizing Pacman mirrorlist"
sudo pacman -S --noconfirm reflector rsync
sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

echo "Installing YAY"
git clone https://aur.archlinux.org/yay.git || { echo "Failed cloning yay: $?"; }
cd yay && sudo make install && cd .. && rm -rf yay
yay -Syu --noconfirm

# system packages --------------------------------

echo "Install system packages"
yay -S --noconfirm nano btop wget unzip zsh
sh -c "$(RUNZSH=no wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# de --------------------------------

echo Initializing XDG user directories
yay -S --noconfirm git man-db vi xdg-user-dirs
xdg-user-dirs-update

echo "Adding $USER to video group"
sudo usermod -aG video $USER

echo "Installing Hyprland"
yay -S --noconfirm hyprland swaync wl-clipboard cliphist tofi brightnessctl polkit-gnome qt5-wayland qt6-wayland gnome-themes-extra gtk3 ttf-dejavu wlsunset

echo "Installing DE apps"
yay -S --noconfirm thunar foot telegram-desktop firefox thorium file-roller

echo "Copy DE configs"
rsync -Ph --recursive nix/configs/home/.config/ .config/

echo "Enable Hyprland autostart"
echo "\nif [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then 
    dbus-run-session Hyprland
fi" >> .zshrc

#timeshift

# dev --------------------------------

echo "Install devel packages"
yay -S --noconfirm base-devel

echo "Setup git"
git config --global user.name "Decard"
git config --global user.email "mail@dayreon.ru"

echo "Install nvm and LTS Node"
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install --lts

# VSCode
echo
yes_or_no "Install VSCode?"

# hangs on load

if [ "$choice" == "Y" ]; then
    yay -S --noconfirm visual-studio-code-bin
    code --install-extension yzhang.markdown-all-in-one
    code --install-extension foxundermoon.shell-format
    rsync -Ph --recursive nix/configs/home/.config/Code/User/ .config/Code/User
else
    echo "Skip"
fi

# Sucket supply
echo
yes_or_no "Install devel packages for socket supply?"

if [ "$choice" == "Y" ]; then
    yay -S --noconfirm webkit2gtk-4.1 clang libc++abi libpthread-stubs at-spi2-core gcc
else
    echo "Skip"
fi

# virt --------------------------------

echo "Done. You need to reboot."
