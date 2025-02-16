# Офигенная установка NixOS

## Установка с ISO

### Подготовка

1. Скачай [NixOS minimal ISO](https://nixos.org/download#nixos-iso)
2. Загрузись с флешки
3. Подключись к интернету:

```bash
sudo systemctl start wpa_supplicant
wpa_cli
	add_network
	set_network 0 ssid "JoraNet"
	set_network 0 psk "PASSWORD"
	enable_network 0
ping ya.ru
```

### Установка

1. Размечаем диск, форматируем и монтируем его:

```bash
sudo nix \
    --experimental-features 'flakes nix-command' \
    run github:nix-community/disko -- \
    -f github:decard2/nix#emerald \
    -m destroy,format,mount
```

2. Устанавливаем ОС:

```bash
sudo nixos-install --flake github:decard2/nix#emerald
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
# Преключаем систему на наш репо
sudo rm -rf /etc/nixos
sudo ln -s ~/nix /etc/nixos
```

Profit! 🎉
