# Update packages
```zsh
cd nix
nix flake update
sudo nixos-rebuild boot --flake .#lemerald
sudo nixos-rebuild switch --flake .#lemerald
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
```
# Delete generations
```zsh
cd nix
nix-collect-garbage -d
sudo nixos-rebuild switch --flake .#lemerald
```