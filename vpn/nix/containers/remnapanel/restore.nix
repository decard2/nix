# Database restore utility for Remnawave Panel
{
  pkgs,
  ...
}:

let
  backupDir = "/opt/remnawave/backups";
  dbContainer = "remnawave-db";
  dbName = "remnawave";
  dbUser = "postgres";
  dbPassword = "4362a038f7ffb24c578961ecbb0ab2861d87ef6cd029eac6";

  restoreScript = pkgs.writeShellScript "remnawave-restore" ''
    set -euo pipefail

    BACKUP_DIR="${backupDir}"
    DB_CONTAINER="${dbContainer}"

    if [ $# -eq 0 ]; then
      echo "Usage: remnawave-restore [backup-file|latest]"
      echo ""
      echo "Examples:"
      echo "  remnawave-restore latest"
      echo "  remnawave-restore /opt/remnawave/backups/remnawave_20251005_065447.dump"
      echo ""
      echo "Available backups:"
      ls -lt "$BACKUP_DIR"/remnawave_*.dump 2>/dev/null | head -5 || echo "No backups found"
      exit 1
    fi

    if [ "$1" = "latest" ]; then
      BACKUP_FILE=$(ls -t "$BACKUP_DIR"/remnawave_*.dump 2>/dev/null | head -1)
      if [ -z "$BACKUP_FILE" ]; then
        echo "ERROR: No backup files found in $BACKUP_DIR"
        exit 1
      fi
      echo "Using latest backup: $BACKUP_FILE"
    else
      BACKUP_FILE="$1"
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
      echo "ERROR: Backup file not found: $BACKUP_FILE"
      exit 1
    fi

    echo "WARNING: This will completely replace the current database!"
    echo "Database: ${dbName}"
    echo "Backup file: $BACKUP_FILE"
    echo "Backup date: $(ls -l "$BACKUP_FILE" | ${pkgs.gawk}/bin/awk '{print $6, $7, $8}')"
    echo ""
    read -p "Are you sure? Type 'yes' to continue: " -r

    if [ "$REPLY" != "yes" ]; then
      echo "Restore cancelled"
      exit 0
    fi

    echo "Starting database restore..."

    # Останавливаем backend контейнер
    echo "Stopping backend container..."
    ${pkgs.podman}/bin/podman stop remnawave-backend || true

    # Копируем бекап в контейнер БД
    echo "Copying backup file to database container..."
    ${pkgs.podman}/bin/podman cp "$BACKUP_FILE" "$DB_CONTAINER:/tmp/restore.dump"

    # Дропаем все соединения к БД
    echo "Terminating database connections..."
    ${pkgs.podman}/bin/podman exec "$DB_CONTAINER" psql -U ${dbUser} -d postgres -c \
      "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${dbName}' AND pid <> pg_backend_pid();" || true

    # Восстанавливаем базу данных
    echo "Restoring database..."
    ${pkgs.podman}/bin/podman exec "$DB_CONTAINER" pg_restore \
      -U ${dbUser} \
      -d ${dbName} \
      --verbose \
      --clean \
      --if-exists \
      --no-owner \
      --no-acl \
      /tmp/restore.dump

    # Удаляем временный файл
    ${pkgs.podman}/bin/podman exec "$DB_CONTAINER" rm -f /tmp/restore.dump

    # Запускаем backend обратно
    echo "Starting backend container..."
    ${pkgs.podman}/bin/podman start remnawave-backend

    echo ""
    echo "Database restored successfully!"
    echo "Backend container restarted."
  '';

  listBackupsScript = pkgs.writeShellScript "remnawave-list-backups" ''
    BACKUP_DIR="${backupDir}"

    echo "Available backups:"
    echo "=================="

    if ! ls "$BACKUP_DIR"/remnawave_*.dump >/dev/null 2>&1; then
      echo "No backup files found in $BACKUP_DIR"
      exit 1
    fi

    ls -lht "$BACKUP_DIR"/remnawave_*.dump | while read -r line; do
      filename=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $NF}')
      size=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $5}')
      date=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $6, $7, $8}')
      echo "$date  $size  $(basename "$filename")"
    done
  '';
in
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "remnawave-restore" ''
      export PGPASSWORD="${dbPassword}"
      exec ${restoreScript} "$@"
    '')
    (pkgs.writeShellScriptBin "remnawave-list-backups" ''exec ${listBackupsScript} "$@"'')
  ];
}
