# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal NixOS flake configuration managing:
- **emerald** — main workstation (Intel CPU, NVIDIA GPU, Hyprland desktop)
- **VPN infrastructure** — Remnawave VPN on GCP (panel + Stockholm/Helsinki nodes), defined in `vpn/`

Language: Nix. User language: Russian.

## Common Commands

```bash
# Rebuild local system
sudo nixos-rebuild switch --flake .#emerald

# Build bootable ISO
nix build

# Deploy VPN server remotely
NIX_SSHOPTS="-p 4444" nixos-rebuild switch --refresh --flake .#hostname --target-host rolder@TARGET_IP --ask-sudo-password

# Install VPN server from scratch
./vpn/nix/install.sh -k ~/.ssh/rolder-net-gcp -u roldernet_gmail_com remnapanel 34.51.236.162

# Format with nixfmt
nixfmt <file.nix>
```

## Architecture

Two independent flakes:
- **Root `flake.nix`** — workstation config (`nixosConfigurations.emerald` + ISO package)
- **`vpn/nix/flake.nix`** — VPN servers (`stockholm`, `helsinki`, `remnapanel`)

### Workstation structure

```
system/           # NixOS system modules
  hardware.nix    # CPU/GPU detection, NVIDIA prime offload
  system.nix      # Boot, locale, users, audio (PipeWire)
  network.nix     # Networking, sing-box VPN proxy, firewall
  packages.nix    # System-wide packages
  disko.nix       # Declarative disk layout (NVMe, EXT4, 16GB swap)
  services/       # Transmission, USB
  virtualization/ # Docker, libvirt, Windows 11 VM

home/             # Home Manager user config
  de/             # Hyprland WM, GTK theme, fonts, yofi launcher
  dev/            # Git, SSH keys, Bun, Flox, Devbox, Zed editor
  shell/          # Fish shell, starship prompt, aliases, functions
  programs/       # Firefox, Telegram, Kitty terminal, Chrome
  devops/         # Kubernetes, S3 tools
  scripts/        # Deployment and automation scripts
```

### VPN structure

```
vpn/nix/
  common.nix          # Shared base (SSH on 4444, firewall, rolder user)
  containers/         # Docker containers (remnapanel, remnanode, selfsteal)
vpn/terraform/        # GCP infrastructure provisioning
```

### Key patterns

- Each directory has a `default.nix` that imports its submodules
- Home Manager is integrated as a NixOS module (not standalone)
- Unfree packages are allowed globally
- Nix substituters: cache.nixos.org, nix-community.cachix.org, hyprland.cachix.org, cache.flox.dev

## Code Style

- Functional Nix style, avoid imperative patterns
- Use attribute sets over positional arguments
- Format with `nixfmt`
- Modularize to avoid duplication
