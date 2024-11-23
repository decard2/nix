#!/usr/bin/env nu

def cleanup [] {
    echo $"(ansi yellow)🧹 Cleaning up previous installation...(ansi reset)"

    # Unmount everything in reverse order
    do --ignore-errors { ^swapoff -a }
    do --ignore-errors { ^umount -Rl /mnt }

    # Очистим /mnt
    if ('/mnt' | path exists) {
        rm -rf /mnt/*
    }

    echo $"(ansi green)✅ Cleanup done!(ansi reset)"
}

def main [] {
    cleanup

    echo $"(ansi green_bold)🚀 Welcome! Let's install NixOS!(ansi reset)"

    # Check EFI mode
    if not ('/sys/firmware/efi' | path exists) {
        echo $"(ansi red)❌ System is not in EFI mode! Please reboot in EFI mode!(ansi reset)"
        exit 1
    }

    # Check mkpasswd
    if (which mkpasswd | is-empty) {
        echo "📦 Installing mkpasswd..."
        ^nix-env -iA nixos.mkpasswd
    }

    # Check internet
    if (do --ignore-errors { ^ping -c 1 google.com } | complete).exit_code != 0 {
        setup_wifi
    }

    echo $"(ansi yellow)📡 Network is ready, let's continue!(ansi reset)"

    # Ask about disk
    let disk = select_disk

    echo $"(ansi yellow)💾 Selected disk for installation: ($disk)(ansi reset)"
    if (input "Are you sure? This will erase all data! [y/N] ") != "y" {
        echo "Operation cancelled!"
        exit 1
    }

    # Partition disk
    partition_disk $disk

    # Get config
    echo $"(ansi green)🔄 Setting up configuration...(ansi reset)"

    # Create necessary directories
    ^mkdir -p /mnt/etc
    ^mkdir -p /mnt/home/decard

    # Check if we have the repo
    if not ('tmp/nix' | path exists) {
        echo $"(ansi red)❌ Configuration not found in /tmp/nix!(ansi reset)"
        exit 1
    }

    # Move cloned repo to final location
    mv /tmp/nix /mnt/etc/nixos

    # Create symlink in home directory
    cd /mnt/home/decard
    ^ln -s ../../etc/nixos nix

    # Generate configs
    echo $"(ansi green)🔧 Generating hardware-configuration.nix...(ansi reset)"
    ^nixos-generate-config --root /mnt --no-filesystems

    # Copy to the correct location in repository
    cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/decard/nix/hosts/emerald/hardware.nix

    # Set root password
    echo $"(ansi yellow)🔑 Let's set root password!(ansi reset)"
    loop {
        let passwd = (input-passwd "Enter root password: ")
        let passwd2 = (input-passwd "Confirm password: ")
        if $passwd == $passwd2 {
            $passwd | ^mkpasswd -m sha-512 | save -f /mnt/etc/shadow.root
            break
        }
        echo $"(ansi red)❌ Passwords don't match, try again!(ansi reset)"
    }

    # Set user password
    echo $"(ansi yellow)🔑 Now set password for decard!(ansi reset)"
    loop {
        let passwd = (input-passwd "Enter password for decard: ")
        let passwd2 = (input-passwd "Confirm password: ")
        if $passwd == $passwd2 {
            $passwd | ^mkpasswd -m sha-512 | save -f /mnt/etc/shadow.user
            break
        }
        echo $"(ansi red)❌ Passwords don't match, try again!(ansi reset)"
    }

    # Start installation
    echo $"(ansi green_bold)🚀 Ready to start installation!(ansi reset)"
    if (input "Begin installation? [y/N] ") == "y" {
        ^nixos-install --flake /mnt/etc/nixos#emerald --root-passwd-file /mnt/etc/shadow.root --passwd-file /mnt/etc/shadow.user
    }
}

def setup_wifi [] {
    echo $"(ansi yellow)😱 No internet connection! Let's fix that...(ansi reset)"

    echo "Launching iwctl, follow these steps:"
    echo "1. station wlan0 scan"
    echo "2. station wlan0 get-networks"
    echo "3. station wlan0 connect \"Network_Name\""
    echo "4. exit"

    ^iwctl

    if (do --ignore-errors { ^ping -c 1 google.com } | complete).exit_code != 0 {
        echo $"(ansi red)❌ Still no internet connection...(ansi reset)"
        exit 1
    }
}

def select_disk [] {
    echo $"(ansi yellow)💽 Available disks:(ansi reset)"
    let disks = (^lsblk -dpno NAME,SIZE | lines | each { |it| $it | str trim })

    for disk in $disks {
        echo $"  ($disk)"
    }

    let selected = (input "Select installation disk (full path, e.g. /dev/sda): ")
    if ($selected | path exists) {
        $selected
    } else {
        echo $"(ansi red)❌ Invalid disk path!(ansi reset)"
        exit 1
    }
}

def partition_disk [disk: string] {
    echo $"(ansi yellow)🔪 Partitioning disk: ($disk)(ansi reset)"

    # Parse RAM for swap
    let ram = (^free -g | lines | get 1 | split row -r '\s+' | get 1 | into int)
    let swap_size = ($ram * 2)

    # Clean disk just in case
    ^wipefs -af $disk

    # Partition
    ^parted $disk -- mklabel gpt
    ^parted $disk -- mkpart ESP fat32 1MiB 1GiB
    ^parted $disk -- set 1 esp on
    ^parted $disk -- mkpart primary linux-swap 1GiB $"($swap_size + 1)GiB"
    ^parted $disk -- mkpart primary $"($swap_size + 1)GiB" 100%

    # Format partitions
    echo "Formatting EFI partition..."
    ^mkfs.fat -F 32 -n "EFI" $"($disk)1"

    echo "Creating SWAP..."
    ^mkswap -L "swap" $"($disk)2"

    echo "Formatting BTRFS partition..."
    ^mkfs.btrfs -L "nixos" $"($disk)3"

    # Mount BTRFS and create subvolumes
    echo "Creating subvolumes..."
    ^mount $"($disk)3" /mnt

    # Create subvolumes
    ^btrfs subvolume create /mnt/@
    ^btrfs subvolume create /mnt/@home
    ^btrfs subvolume create /mnt/@nix
    ^btrfs subvolume create /mnt/@cache
    ^btrfs subvolume create /mnt/@log

    # Unmount temporary mount point
    do --ignore-errors { ^umount -Rl /mnt }

    # Mount everything properly
    echo "Mounting partitions..."
    ^mount -o subvol=@,compress=zstd,noatime $"($disk)3" /mnt

    ^mkdir -p /mnt/{home,nix,boot/efi,var/cache,var/log}

    ^mount -o subvol=@home,compress=zstd,noatime $"($disk)3" /mnt/home
    ^mount -o subvol=@nix,compress=zstd,noatime $"($disk)3" /mnt/nix
    ^mount -o subvol=@cache,compress=zstd,noatime $"($disk)3" /mnt/var/cache
    ^mount -o subvol=@log,compress=zstd,noatime $"($disk)3" /mnt/var/log
    ^mount $"($disk)1" /mnt/boot/efi
    ^swapon $"($disk)2"

    echo $"(ansi green)✅ Disk partitioned and mounted!(ansi reset)"
}

main
