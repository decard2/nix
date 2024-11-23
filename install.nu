#!/usr/bin/env nu

let-env LANG = "ru_RU.UTF-8"

def main [] {
    print $"(ansi green_bold)🚀 Здорова, братиш! Погнали ставить NixOS!(ansi reset)"

    # Проверяем EFI режим
    if not (test -d /sys/firmware/efi) {
        print $"(ansi red)❌ Братиш, система не в EFI режиме! Перезагрузись в EFI!(ansi reset)"
        exit 1
    }

    # Проверяем есть ли mkpasswd, если нет - ставим
    if (which mkpasswd | is-empty) {
        print "📦 Ставлю mkpasswd..."
        nix-env -iA nixos.mkpasswd
    }

    # Проверяем интернет
    if (do --ignore-errors { ping -c 1 google.com } | complete).exit_code != 0 {
        setup_wifi
    }

    print $"(ansi yellow)📡 Сеть на месте, погнали дальше!(ansi reset)"

    # Спрашиваем про диск
    let disk = select_disk

    print $"(ansi yellow)💾 Будем разбивать диск: ($disk)(ansi reset)"
    if (input "Точно его разбиваем? [y/N] ") != "y" {
        print "Ну нет так нет, давай по новой!"
        exit 1
    }

    # Размечаем диски
    partition_disk $disk

    # Качаем конфиг
    print $"(ansi green)🔄 Ща конфиг подтяну...(ansi reset)"

    # Сначала клоним в домашнюю директорию
    ^mkdir -p /mnt/home/decard/nix
    git clone https://github.com/decard2/nix.git /mnt/home/decard/nix

    # Потом делаем симлинк в /etc/nixos
    ^mkdir -p /mnt/etc
    ln -s /home/decard/nix /mnt/etc/nixos

    # Генерим конфиги
    print $"(ansi green)🔧 Генерю hardware-configuration.nix...(ansi reset)"
    nixos-generate-config --root /mnt --no-filesystems

    # Обновляем конфиги для systemd-boot
    print $"(ansi green)🔄 Обновляем конфиги для systemd-boot...(ansi reset)"
    nixos-generate-config --root /mnt

    # Теперь копируем в правильное место в репозитории
    cp /mnt/etc/nixos/hardware-configuration.nix /mnt/home/decard/nix/hosts/emerald/hardware.nix

    # Задаём пароль рута
    print $"(ansi yellow)🔑 Братиш, давай пароль рута зададим!(ansi reset)"
    while true {
        let passwd = input --password "Введи пароль для root: "
        let passwd2 = input --password "И ещё разок для проверки: "
        if $passwd == $passwd2 {
            $passwd | mkpasswd -m sha-512 | save -f /mnt/etc/shadow.root
            break
        }
        print $"(ansi red)❌ Пароли не совпадают, давай по новой!(ansi reset)"
    }

    # И для твоего юзера
    print $"(ansi yellow)🔑 Теперь пароль для decard!(ansi reset)"
    while true {
        let passwd = input --password "Введи пароль для decard: "
        let passwd2 = input --password "И ещё разок для проверки: "
        if $passwd == $passwd2 {
            $passwd | mkpasswd -m sha-512 | save -f /mnt/etc/shadow.user
            break
        }
        print $"(ansi red)❌ Пароли не совпадают, давай по новой!(ansi reset)"
    }

    # Погнали ставить!
    print $"(ansi green_bold)🚀 Ну чё, погнали ставить эту красоту?(ansi reset)"
    if (input "Начинаем установку? [y/N] ") == "y" {
        nixos-install --flake /mnt/etc/nixos#emerald --root-passwd-file /mnt/etc/shadow.root --passwd-file /mnt/etc/shadow.user
    }
}

def setup_wifi [] {
    print $"(ansi yellow)😱 Вот жеж, инета нет! Щас порешаем...(ansi reset)"

    # Запускаем iwctl в интерактивном режиме
    print "Ща iwctl запущу, там сделай:"
    print "1. station wlan0 scan"
    print "2. station wlan0 get-networks"
    print "3. station wlan0 connect \"Имя_Сети\""
    print "4. exit"

    iwctl

    if (do --ignore-errors { ping -c 1 google.com } | complete).exit_code != 0 {
        print $"(ansi red)❌ Не, братан, инет так и не появился...(ansi reset)"
        exit 1
    }
}

def select_disk [] {
    print $"(ansi yellow)💽 Доступные диски:(ansi reset)"
    let disks = (lsblk -dpno NAME,SIZE | lines | each { |it| $it | str trim })

    for disk in $disks {
        print $"  ($disk)"
    }

    let selected = input "На какой диск ставим? (полный путь, типа /dev/sda): "
    if ($selected | path exists) {
        $selected
    } else {
        print $"(ansi red)❌ Не, такого диска нет!(ansi reset)"
        exit 1
    }
}

def partition_disk [disk: string] {
    print $"(ansi yellow)🔪 Размечаем диск: ($disk)(ansi reset)"

    # Парсим RAM для свопа
    let ram = (free -g | lines | $in.1 | split row -r '\s+' | $in.1 | into int)
    let swap_size = ($ram * 2)

    # Чистим диск на всякий
    wipefs -af $disk

    # Размечаем
    parted $disk -- mklabel gpt
    parted $disk -- mkpart ESP fat32 1MiB 1GiB
    parted $disk -- set 1 esp on
    parted $disk -- mkpart primary linux-swap 1GiB $"($swap_size + 1)GiB"
    parted $disk -- mkpart primary $"($swap_size + 1)GiB" 100%

    # Форматируем разделы
    print "Форматируем EFI раздел..."
    mkfs.fat -F 32 -n "EFI" $"($disk)1"

    print "Создаём SWAP..."
    mkswap -L "swap" $"($disk)2"

    print "Форматируем BTRFS раздел..."
    mkfs.btrfs -L "nixos" $"($disk)3"

    # Монтируем BTRFS и создаём сабволюмы
    print "Создаём сабволюмы..."
    mount $"($disk)3" /mnt

    # Создаём сабволюмы
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@nix
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@log

    # Отмонтируем временную точку
    umount /mnt

    # Монтируем всё как надо
    print "Монтируем разделы..."
    mount -o subvol=@,compress=zstd,noatime $"($disk)3" /mnt

    ^mkdir -p /mnt/{home,nix,boot/efi,var/cache,var/log}

    mount -o subvol=@home,compress=zstd,noatime $"($disk)3" /mnt/home
    mount -o subvol=@nix,compress=zstd,noatime $"($disk)3" /mnt/nix
    mount -o subvol=@cache,compress=zstd,noatime $"($disk)3" /mnt/var/cache
    mount -o subvol=@log,compress=zstd,noatime $"($disk)3" /mnt/var/log
    mount $"($disk)1" /mnt/boot/efi
    swapon $"($disk)2"

    print $"(ansi green)✅ Диск размечен и примонтирован!(ansi reset)"
}

main
