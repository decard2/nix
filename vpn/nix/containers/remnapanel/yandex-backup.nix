# Yandex Object Storage backup synchronization for Remnawave Panel
# Using systemd path unit for automatic sync on file changes
{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.services.remnawave-yandex-backup;
  backupDir = "/opt/remnawave/backups";
  rcloneConfigFile = "/etc/rclone/rclone.conf";

  # Создаем конфигурацию rclone декларативно
  rcloneConfig = ''
    [yandex]
    type = s3
    provider = Other
    access_key_id = ${cfg.accessKeyId}
    secret_access_key = ${cfg.secretAccessKey}
    endpoint = https://storage.yandexcloud.net
    region = ru-central1
    force_path_style = false
  '';

  # Скрипт для синхронизации с Yandex Object Storage
  syncToYandexScript = pkgs.writeShellScript "yandex-backup-sync" ''
    set -euo pipefail

    BACKUP_DIR="${backupDir}"
    BUCKET_NAME="${cfg.bucketName}"
    FOLDER_PATH="${cfg.folderPath}"
    REMOTE_PATH="yandex:$BUCKET_NAME/$FOLDER_PATH"

    echo "$(date): Syncing backups to Yandex Object Storage..."

    # Проверяем наличие локальных бекапов
    if ! ls "$BACKUP_DIR"/remnawave_*.dump >/dev/null 2>&1; then
      echo "$(date): No backup files found, skipping sync"
      exit 0
    fi

    # Синхронизируем только новые файлы с Yandex Object Storage
    ${pkgs.rclone}/bin/rclone copy \
      "$BACKUP_DIR" \
      "$REMOTE_PATH" \
      --config "${rcloneConfigFile}" \
      --include "remnawave_*.dump" \
      --transfers 2 \
      --retries 3 \
      --max-age 24h

    echo "$(date): Sync completed successfully"

    # Очищаем старые файлы в облаке (старше 180 дней)
    ${pkgs.rclone}/bin/rclone delete \
      "$REMOTE_PATH" \
      --config "${rcloneConfigFile}" \
      --min-age 180d || true

    echo "$(date): Cleanup completed"
  '';

  # Скрипт для скачивания бекапов из облака
  downloadFromYandexScript = pkgs.writeShellScript "yandex-backup-download" ''
    set -euo pipefail

    BACKUP_DIR="${backupDir}"
    BUCKET_NAME="${cfg.bucketName}"
    FOLDER_PATH="${cfg.folderPath}"
    REMOTE_PATH="yandex:$BUCKET_NAME/$FOLDER_PATH"

    # Количество бекапов для скачивания (по умолчанию 1)
    COUNT=''${1:-1}

    if [ "$COUNT" -le 0 ]; then
      echo "ERROR: Count must be a positive number"
      exit 1
    fi

    echo "$(date): Downloading $COUNT latest backup(s) from Yandex Object Storage..."

    ${pkgs.coreutils}/bin/mkdir -p "$BACKUP_DIR"

    # Получаем список файлов, сортируем по времени, берем нужное количество
    TEMP_LIST=$(${pkgs.coreutils}/bin/mktemp)
    ${pkgs.rclone}/bin/rclone lsf \
      "$REMOTE_PATH" \
      --config "${rcloneConfigFile}" \
      --include "remnawave_*.dump" | \
    ${pkgs.coreutils}/bin/sort -r | \
    ${pkgs.coreutils}/bin/head -n "$COUNT" > "$TEMP_LIST"

    if [ ! -s "$TEMP_LIST" ]; then
      echo "No backup files found in cloud storage"
      rm -f "$TEMP_LIST"
      exit 1
    fi

    echo "Files to download:"
    ${pkgs.coreutils}/bin/cat "$TEMP_LIST"

    # Скачиваем файлы по списку
    while read -r filename; do
      echo "Downloading: $filename"
      ${pkgs.rclone}/bin/rclone copyto \
        "$REMOTE_PATH/$filename" \
        "$BACKUP_DIR/$filename" \
        --config "${rcloneConfigFile}" \
        --transfers 2 \
        --retries 3
    done < "$TEMP_LIST"

    rm -f "$TEMP_LIST"

    echo "$(date): Download completed"

    # Показываем что скачали
    echo "Downloaded backups:"
    ls -lht "$BACKUP_DIR"/remnawave_*.dump 2>/dev/null || echo "No backups found"
  '';
in
{
  options.services.remnawave-yandex-backup = {
    enable = mkEnableOption "Yandex Object Storage backup sync for Remnawave";

    accessKeyId = mkOption {
      type = types.str;
      description = "Yandex Object Storage access key ID";
    };

    secretAccessKey = mkOption {
      type = types.str;
      description = "Yandex Object Storage secret access key";
    };

    bucketName = mkOption {
      type = types.str;
      description = "Yandex Object Storage bucket name";
    };

    folderPath = mkOption {
      type = types.str;
      default = "remnawave-backups";
      description = "Folder path in the bucket for backups";
    };
  };

  config = mkIf cfg.enable {
    # Устанавливаем rclone и команду синхронизации
    environment.systemPackages = [
      pkgs.rclone
      (pkgs.writeShellScriptBin "remnawave-sync-yandex" ''exec ${syncToYandexScript} "$@"'')
      (pkgs.writeShellScriptBin "remnawave-download-yandex" ''exec ${downloadFromYandexScript} "$@"'')
    ];

    # Создаем конфигурацию rclone
    environment.etc."rclone/rclone.conf" = {
      text = rcloneConfig;
      mode = "0644";
    };

    # Сервис для синхронизации с Yandex Object Storage
    systemd.services.remnawave-yandex-backup-sync = {
      description = "Sync Remnawave backups to Yandex Object Storage";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${syncToYandexScript}";
        PrivateTmp = true;
      };
    };

    # Path unit для автоматической синхронизации при изменениях
    systemd.paths.remnawave-yandex-backup-sync = {
      description = "Watch backup directory for changes";
      wantedBy = [ "multi-user.target" ];

      pathConfig = {
        PathModified = backupDir;
        Unit = "remnawave-yandex-backup-sync.service";
      };
    };
  };
}
