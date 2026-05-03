# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal NixOS flake for **emerald** — main workstation (Intel CPU, NVIDIA GPU, Hyprland desktop).

Language: Nix. User language: Russian.

## Common Commands

```bash
# Rebuild local system
sudo nixos-rebuild switch --flake .#emerald

# Build bootable ISO
nix build

# Format with nixfmt
nixfmt <file.nix>
```

## Architecture

Single flake `flake.nix` — workstation config (`nixosConfigurations.emerald` + ISO package).

### Structure

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
  programs/       # Firefox, Telegram, Chrome
  devops/         # Kubernetes, S3 tools
  scripts/        # Deployment and automation scripts
```

### Key patterns

- Each directory has a `default.nix` that imports its submodules
- Home Manager is integrated as a NixOS module (not standalone)
- Unfree packages are allowed globally
- Nix substituters: cache.nixos.org, nix-community.cachix.org, hyprland.cachix.org, cache.flox.dev

## Docs

- `docs/document-signing.md` — нативная схема подписи Точки/Диадока аппаратным
  ключом Rutoken Lite (CryptoPro CSP + Cades + Контур.Плагин, без distrobox).
  Установка с нуля + грабли.
- `docs/research/` — исследовательские документы перед крупными изменениями.
  Индекс: [`docs/research/README.md`](docs/research/README.md).

## Code Style

- Functional Nix style, avoid imperative patterns
- Use attribute sets over positional arguments
- Format with `nixfmt`
- Modularize to avoid duplication
