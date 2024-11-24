# Офигенная установка NixOS

## Установка с ISO

sudo nix \
    --experimental-features 'flakes nix-command' \
    run github:nix-community/disko#disko-install -- \
    --flake "github:decard2/nix#emerald" \
    --write-efi-boot-entries \
    --disk main "/dev/vda"

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
curl https://raw.githubusercontent.com/decard2/nix/main/nixos/disko.nix -o /tmp/disko.nix
```

2. Размечаем диск через disko:
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disko.nix
```

3. Генерим конфиг оборудования:
```bash
sudo mkdir -p /mnt/home/decard/
sudo chown -R 1000:1000 /mnt/home/decard
cd /mnt/home/decard
sudo nix-env -iA nixos.git
git clone https://github.com/decard2/nix.git
sudo nixos-generate-config --no-filesystems --root /mnt --dir /mnt/home/decard/nix/nixos

#sudo curl https://raw.githubusercontent.com/decard2/nix/main/flake.nix -o ./flake.nix
#sudo cp /mnt/etc/nixos/hardware-configuration.nix ./nixos/
#sudo mkdir -p /mnt/home/decard/
#sudo cp -r ../nix /mnt/home/decard/
#sudo chown -R 1000:1000 /mnt/home/decard/nix
```

4. Устанавливаем систему:
```bash
sudo nixos-install --flake '/mnt/home/decard/nix#emerald'
```

5. Перезагружаемся:
```bash
reboot
```

### После установки

1. Логинимся под юзером decard (пароль по умолчанию: changeme)
2. Первым делом меняем пароль:
```bash
passwd
```
3. Все конфиги системы находятся в ~/nix
4. Profit! 🎉
