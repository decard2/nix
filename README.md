# Install Arch

* [Download](https://archlinux.org/download/)
* Flash USB - `dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sda conv=fsync oflag=direct status=progress`
* WiFi - `iwctl`:
  * `station wlan0 scan`
  * `station wlan0 connect {wifi name}`
* Install Arch:
  * Start arch install script: `archinstall`
    * btrfs - defaults.
    * Minimal profile.
    * Sound - pipewire.
    * Kernel - zen.
    * Packages: `wget git base-devel`
    * Network: copy ISO
    * Set timezone
    * No chroot.
* Git repo: `git clone https://github.com/dayreon/nix.git`
* Start script: `./nix/arch/scripts/install.sh`
