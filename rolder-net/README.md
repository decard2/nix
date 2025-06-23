# NixOS Anywhere - Automated Server Installation

This project provides automated NixOS installation on remote servers using `nixos-anywhere`. Designed for fully automated deployment without manual intervention.

## Overview

- **Purpose**: Install NixOS 25.05 on remote servers automatically
- **Target**: KVM/QEMU virtual machines or bare metal servers
- **Authentication**: Password-based (no SSH keys required)
- **Automation Level**: Fully automated, no user confirmation needed

## Project Structure

```
devops/rolder-net-nix/
├── flake.nix              # NixOS flake configuration
├── flake.lock             # Dependency lock file
├── configuration.nix      # System configuration template
├── disk-config.nix        # Disk partitioning (disko)
├── hardware-configuration.nix # Hardware config (auto-generated)
├── install.sh             # Installation script
└── README.md              # This file
```

## Quick Start

### Prerequisites

- Nix with flakes enabled
- `sshpass` installed
- Target server with SSH access (port 22)

### Installation Command

```bash
./install.sh HOSTNAME TARGET_IP PASSWORD
```

**Example:**

```bash
./install.sh warsaw 95.164.35.228 'MyPassword123'
```

### What Happens

1. **Validation**: Checks SSH connectivity and flake configuration
2. **Password Hashing**: Generates secure hash for user password
3. **Kexec Boot**: Loads NixOS installer into target system memory
4. **Disk Setup**: Partitions and formats disk according to configuration
5. **Installation**: Installs NixOS with custom configuration
6. **Reboot**: System reboots into new NixOS installation

## System Configuration

### Default Setup

- **OS Version**: NixOS 25.05
- **User**: `rolder` with sudo privileges
- **SSH Port**: 4444 (changed from default 22)
- **Authentication**: Password + SSH keys (optional)
- **Firewall**: Enabled, only SSH port open
- **VM Tools**: QEMU guest agent for KVM/QEMU
- **Root Access**: Disabled for security

### Disk Layout

- **Disk**: `/dev/vda` (KVM default)
- **Partitions**:
  - 512MB EFI boot partition (FAT32)
  - Remaining space for root (ext4)
- **No**: LVM, encryption, or swap

### Installed Packages

Basic server tools: `git`, `curl`, `htop`

## Multi-Host Support

### Host Configurations

The flake supports multiple host configurations:

- **server**: Generic configuration (default)
- **warsaw**: Specific host configuration

### Adding New Hosts

To add a new host configuration, edit `flake.nix`:

```nix
nixosConfigurations.newhostname = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    hostname = "newhostname";
    rolderPassword = "generated-hash";
  };
  modules = [
    disko.nixosModules.disko
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
  ];
};
```

## Script Options

```bash
./install.sh [OPTIONS] HOSTNAME TARGET_IP [PASSWORD]

Options:
  -u, --user USER     SSH user (default: root)
  -p, --port PORT     SSH port for installation (default: 22)
  -h, --help          Show help
```

## Post-Installation

### Connecting to System

```bash
ssh -p 4444 rolder@TARGET_IP
```

Use the password specified during installation.

### System Updates

```bash
# On the server
sudo nixos-rebuild switch --flake github:username/repo#hostname

# Or remotely
nixos-rebuild switch --flake .#hostname --target-host rolder@TARGET_IP --use-remote-sudo
```

## Technical Details

### Dependencies

- **nixos-anywhere**: Handles remote installation
- **disko**: Manages disk partitioning and formatting
- **sshpass**: Enables automated password authentication

### Security Features

- Non-standard SSH port (4444)
- Root login disabled
- Password authentication with strong hashing
- Firewall enabled by default
- VM-specific hardening

### Automation Features

- Zero-confirmation installation
- Automatic password hashing
- Hardware configuration generation
- Temporary configuration handling
- Error handling and cleanup

## Use Cases

### Development/Testing

Quick deployment of NixOS environments for development or testing purposes.

### Infrastructure as Code

Reproducible server configurations with version control and rollback capabilities.

### VM Provisioning

Automated setup of KVM/QEMU virtual machines with consistent configuration.

## Error Handling

Common issues and solutions:

- **SSH Connection Failed**: Check network connectivity and credentials
- **Disk Configuration Error**: Verify disk device in `disk-config.nix`
- **Flake Build Error**: Run `nix flake check` to validate configuration
- **Installation Timeout**: Check server resources and network speed

## Maintenance

### Updating Dependencies

```bash
nix flake update
```

### Validating Configuration

```bash
nix flake check
```

### Testing Configuration

```bash
nix build .#nixosConfigurations.hostname.config.system.build.toplevel
```

---

**Created for**: Automated NixOS deployment
**Version**: NixOS 25.05
**Architecture**: x86_64-linux
**License**: MIT
