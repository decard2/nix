# Офигенная установка NixOS

## Установка с ISO

### Подготовка
1. Скачай [NixOS minimal ISO](https://nixos.org/download#nixos-iso)
2. Загрузись с флешки
3. Подключись к интернету:
```bash
sudo systemctl start NetworkManager
nmtui  # или просто воткни ethernet
```

### Установка

1. Склонируй репозиторий:
```bash
cd /tmp
sudo nix-env -iA nixos.git
git clone https://github.com/decard2/nix
```

2. Генерим конфиг оборудования:
```bash
nixos-generate-config --no-filesystems --dir /tmp/nix/nixos
```

3. Размечаем диск и устанавливаем систему через disko-install:
```bash
sudo nix \
    --experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "/tmp/nix#emerald" \
    --write-efi-boot-entries \
    --disk main /dev/nvme0n1
```

4. Перезагружаемся:
```bash
reboot
```

### После установки

1. Логинимся (пароль по умолчанию: changeme)
2. Настривамем систему
```bash
# Первым делом меняем пароль:
passwd
# Повторно делаем git clone
git clone https://github.com/decard2/nix.git
# Преключаем систему на наш репо, создав конфиг железа повторно
sudo nixos-generate-config --no-filesystems --dir ./nix/nixos
cd nix
git add nixos/hardware-configuration.nix
sudo nixos-rebuild switch --flake ".#emerald"
```
3. Все конфиги системы находятся в ~/nix
4. Profit! 🎉
