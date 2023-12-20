# Command hints

## Update packages

```zsh
cd nix
nix flake update
sudo nixos-rebuild switch --flake .#lemerald
```

## Delete generations

```zsh
cd nix
nix-collect-garbage -d
sudo nixos-rebuild boot --flake .#lemerald
```