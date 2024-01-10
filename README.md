# Install Arch

* [Download](https://archlinux.org/download/)
* Flash USB - `dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/sda conv=fsync oflag=direct status=progress`
* WiFi - `iwctl`:
  * `station wlan0 scan`
  * `station wlan0 connect {wifi name}`
* Packages: `wget git`
* Git repo: `git clone https://github.com/dayreon/nix.git`
* Install script: `wget -qO- https://raw.githubusercontent.com/dayreon/nix/main/arch/scripts/install.sh | bash`