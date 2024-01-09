# Install Arch
## System

* [Download](https://archlinux.org/download/)
* Flash USB - `dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sda conv=fsync oflag=direct status=progress`
* WiFi - `iwctl`:
  * `station wlan0 scan`
  * `station wlan0 connect {wifi name}`
* Pacman mirrors: 
  * `sudo pacman -S reflector`
  * `sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist`
* yay:
  * `git clone https://aur.archlinux.org/yay.git`
  * `cd yay`
  * `makepkg -si`
  * `cd ..`
  * `rm -rf yay`
* Main packages: `yay -S nano btop`
* configs: `git clone https://github.com/dayreon/nix.git`
* Git:
  * `git config --global user.name "Decard"`
  * `git config --global user.name "Decard"`

## DE

### Hyprland
wget https://raw.github.com/nwg-piotr/nwg-shell/main/install/arch.sh && chmod u+x arch.sh && ./arch.sh && rm arch.sh
* `yay -S hyprland-git xdg-desktop-portal-hyprland`
* `yay -S kitty dunst wl-clipboard cliphist tofi brightnessctl polkit-kde-agent telegram-desktop qt5-wayland qt6-wayland`
* `cp nix/configs/home/.config/hypr/hyprland.conf .config/hypr/hyprland.conf`
* `mkdir .config/tofi && cp nix/configs/home/.config/tofi/config .config/tofi`
* `Hyprland`

### Apps

* Kitty: 
  * `yay -S kitty`
  * `cp nix/configs/home/.config/kitty/kitty.conf .config/kitty`
* Browser: `yay -S firefox thorium`
* Telegram: `yay -S telegram-desktop`
* VSCode (MS): `ysy -S visual-studio-code-bin`

### KVM