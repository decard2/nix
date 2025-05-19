# Переустановка

## Подготовка

1. backup.fish - внутри настройки
2. В папке nix - nix build
3. sudo dd if=./result/iso/nixos-.iso of=/dev/sda bs=4M status=progress

## Установка

1. Скрипт сам все сделает

### После установки

1. Логинимся (пароль по умолчанию: changeme)
2. Настривамем систему

```bash
passwd
iwctl station wlan0 connect JoraNet
git clone https://github.com/decard2/nix.git
# Преключаем систему на наш репо
sudo rm -rf /etc/nixos
sudo ln -s ~/nix /etc/nixos
```
