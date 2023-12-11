# Удаление всех генераций кроме Х-последних
```zsh
cd nix
./system/scripts/trimgens.sh 7 0 home-manager
sudo nixos-rebuild switch --flake .#lemerald
```