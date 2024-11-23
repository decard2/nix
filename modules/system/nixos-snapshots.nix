{ config, lib, pkgs, ... }:

let
  # Скрипт для создания снапшотов до/после обновления
  snapshotScript = pkgs.writeShellScriptBin "nixos-snapshot" ''
    # Функция для создания снапшота с меткой времени
    create_snapshot() {
      local desc="$1"
      local date=$(date +"%Y-%m-%d_%H:%M:%S")

      # Создаём снапшот корня
      snapper -c root create -d "[$date] $desc"

      # Создаём снапшот home
      snapper -c home create -d "[$date] $desc"

      echo "Created snapshot: $desc"
    }

    case "$1" in
      "pre")
        create_snapshot "Pre-update snapshot"
        ;;
      "post")
        create_snapshot "Post-update snapshot"
        ;;
      *)
        echo "Usage: nixos-snapshot [pre|post]"
        exit 1
        ;;
    esac
  '';

  # Скрипт для безопасного обновления с автоматическими снапшотами
  safeRebuildScript = pkgs.writeShellScriptBin "nixos-safe-rebuild" ''
    set -e

    echo "📸 Creating pre-update snapshot..."
    nixos-snapshot pre

    echo "🚀 Updating system..."
    nixos-rebuild switch --flake /home/decard/nix#emerald

    echo "📸 Creating post-update snapshot..."
    nixos-snapshot post

    echo "✅ Update complete! Use 'snapper list' to view snapshots"
  '';

  # Скрипт для отката к предыдущему снапшоту
  rollbackScript = pkgs.writeShellScriptBin "nixos-rollback" ''
    echo "📋 Available snapshots:"
    snapper -c root list

    echo ""
    read -p "Enter snapshot number to rollback to: " snapshot_number

    if [[ ! $snapshot_number =~ ^[0-9]+$ ]]; then
      echo "❌ Invalid snapshot number!"
      exit 1
    fi

    echo "🔄 Rolling back to snapshot $snapshot_number..."
    snapper -c root rollback "$snapshot_number"

    echo "⚠️ System will reboot now..."
    sleep 3
    reboot
  '';

  cleanTempScript = pkgs.writeShellScriptBin "nixos-clean-temp" ''
      echo "🧹 Cleaning temporary files..."

      echo "Cleaning pacman cache..."
      paccache -r

      echo "Cleaning log files older than 7 days..."
      find /var/log -type f -mtime +7 -delete

      echo "Cleaning systemd journal..."
      journalctl --vacuum-time=7d

      echo "✨ All clean!"
    '';

in {
  environment.systemPackages = [
    snapshotScript
    safeRebuildScript
    rollbackScript
    cleanTempScript
  ];

  # Автоматические снапшоты при обновлении через системный сервис
  systemd.services.nixos-update-snapshots = {
    description = "Create BTRFS snapshots on NixOS updates";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    preStart = "${snapshotScript}/bin/nixos-snapshot pre";
    postStop = "${snapshotScript}/bin/nixos-snapshot post";
  };
}
