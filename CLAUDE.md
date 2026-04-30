# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal NixOS flake configuration managing:
- **emerald** — main workstation (Intel CPU, NVIDIA GPU, Hyprland desktop)
- **VPN infrastructure** — Remnawave VPN on GCP (panel + Helsinki nodes), defined in `vpn/`

Language: Nix. User language: Russian.

## Common Commands

```bash
# Rebuild local system
sudo nixos-rebuild switch --flake .#emerald

# Build bootable ISO
nix build

# Deploy VPN server remotely (SSH config handles port 4444 and key automatically)
nixos-rebuild switch --refresh --flake ./vpn/nix#remnapanel --target-host rolder@rolder.net --sudo
nixos-rebuild switch --refresh --flake ./vpn/nix#helsinki --target-host rolder@fi.rolder.net --sudo
nixos-rebuild switch --refresh --flake ./vpn/nix#helsinkiStandard --target-host rolder@fistandard.rolder.net --sudo

# Install VPN server from scratch
./vpn/nix/install.sh -k ~/.ssh/rolder-net-gcp -u root HOSTNAME IP

# Format with nixfmt
nixfmt <file.nix>

# Remnawave sync — dry-run (safe, read-only)
REMNAWAVE_API_TOKEN="<token>" REMNAWAVE_CONFIGS_DIR="vpn/nix/containers/remnapanel/configs" \
  nix-shell -p python3 python3Packages.requests --run "python3 vpn/nix/containers/remnapanel/sync.py --dry-run"

# Remnawave sync — apply (makes changes, auto-backups DB)
REMNAWAVE_API_TOKEN="<token>" REMNAWAVE_CONFIGS_DIR="vpn/nix/containers/remnapanel/configs" \
  nix-shell -p python3 python3Packages.requests --run "python3 vpn/nix/containers/remnapanel/sync.py --apply --no-backup"
```

## Architecture

Two independent flakes:
- **Root `flake.nix`** — workstation config (`nixosConfigurations.emerald` + ISO package)
- **`vpn/nix/flake.nix`** — VPN servers (`helsinki`, `helsinkiStandard`, `remnapanel`)

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
  common.nix          # Shared base (SSH on 4444, firewall, rolder user, API token)
  containers/
    remnapanel/
      default.nix     # Docker containers (postgres, redis, backend, caddy)
      sync.nix        # Systemd service wrapping sync.py
      sync.py         # Python reconcile script (desired state from JSON → API)
      backup.nix      # PostgreSQL backup (daily + before sync)
      restore.nix     # Restore from backup
      yandex-backup.nix # Offsite backup to Yandex S3
      configs/        # JSON source of truth for all Remnawave entities
    remnanode/        # VPN node containers
    selfsteal/        # Reality selfsteal caddy
vpn/terraform/        # GCP infrastructure provisioning
```

### Remnawave declarative sync

JSON files in `vpn/nix/containers/remnapanel/configs/` are the **single source of truth**. The Python script `sync.py` reconciles them with the Remnawave API.

**Entities and key fields:**

| File | Entity | Key field | Operations |
|------|--------|-----------|------------|
| `node-plugins.json` | node-plugins | `name` | create, update, delete |
| `config-profiles.json` | config-profiles | `uuid` | update only |
| `internal-squads.json` | internal-squads | `uuid` | update only |
| `nodes.json` | nodes | `name` | create, update, delete |
| `hosts.json` | hosts | `remark` | create, update, delete |
| `users.json` | users | `username` | create, update, delete |
| `additional-settings.json` | subscription-settings | (singleton) | update only |

**How it works:**
- Runs as `remnawave-sync.service` (systemd oneshot) on every `nixos-rebuild switch`
- Before apply: auto-backups PostgreSQL via `remnawave-db-backup.service`
- Reconcile order: **plugins** → profiles → squads → nodes + hosts → users → settings
- Nodes reference plugins by name via `activePlugin` field — resolved to `activePluginUuid` at sync time
- Objects in API but not in JSON are **deleted** (for nodes, hosts, users)
- `--dry-run` shows plan without changes, `--apply` executes
- **Never edit the panel manually** — JSON files are the source of truth

**To add/modify/remove a user:** edit `configs/users.json`, then deploy or run sync manually.

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
- JSON config files must be valid strict JSON (no trailing commas — Python's json module is strict)
