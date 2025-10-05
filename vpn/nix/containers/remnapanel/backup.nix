# PostgreSQL backup configuration for Remnawave Panel
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

  backupScript = pkgs.writeShellScript "postgres-backup" ''
    set -euo pipefail

    BACKUP_DIR="${backupDir}"
    DATE=$(${pkgs.coreutils}/bin/date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/remnawave_$DATE.dump"

    ${pkgs.coreutils}/bin/mkdir -p "$BACKUP_DIR"

    echo "Starting PostgreSQL backup at $(${pkgs.coreutils}/bin/date)"

    # Создаем бекап
    ${pkgs.podman}/bin/podman exec ${dbContainer} pg_dump \
      -U ${dbUser} \
      -d ${dbName} \
      --format=custom \
      --compress=9 \
      --file=/tmp/backup.dump

    ${pkgs.podman}/bin/podman cp ${dbContainer}:/tmp/backup.dump "$BACKUP_FILE"
    ${pkgs.podman}/bin/podman exec ${dbContainer} rm -f /tmp/backup.dump

    echo "Backup completed: $BACKUP_FILE"

    # Удаляем старые бекапы (старше 30 дней)
    echo "Cleaning up old backups..."
    ${pkgs.findutils}/bin/find "$BACKUP_DIR" -name "remnawave_*.dump" -mtime +29 -delete
    echo "Old backups cleaned up"
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${backupDir} 0755 root root -"
  ];

  systemd.services.remnawave-db-backup = {
    description = "Backup Remnawave PostgreSQL database";
    after = [ "podman-remnawave-db.service" ];
    wants = [ "podman-remnawave-db.service" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${backupScript}";
    };

    environment = {
      PGPASSWORD = dbPassword;
    };
  };

  systemd.timers.remnawave-db-backup = {
    description = "Daily database backup";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
