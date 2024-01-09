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
* Git:     userName = "Decard";
    userEmail = "mail@dayreon.ru";

## DE

### Hyprland

* `yay -S hyprland-git xdg-desktop-portal-hyprland`
* `yay -S kitty wl-clipboard cliphist tofi brightnessctl polkit-kde-agent telegram-desktop qt5-wayland qt6-wayland`
* `cp nix/configs/home/.conf/hypr/hyprland.conf .config/hypr/hyprland.conf`
* `Hyprland`

### Apps

* Browser: `yay -S firefox thorium`
* Telegram: `yay -S telegram-desktop`
* VSCode (MS): `ysy -S visual-studio-code-bin`

### KVM