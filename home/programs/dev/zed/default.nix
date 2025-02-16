{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixd
    nixfmt-rfc-style
    curl
    gnutar
    gzip
  ];

  home.activation.installZed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f $HOME/.local/bin/zed ]; then
      export PATH="${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH"
      ${pkgs.curl}/bin/curl -f https://zed.dev/install.sh | PATH="${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH" sh
    fi
  '';

  home.activation.copyZedSettings = lib.hm.dag.entryAfter [ "installZed" ] ''
    ZED_SETTINGS_DIR="$HOME/.config/zed"
    ZED_SETTINGS_FILE="$ZED_SETTINGS_DIR/settings.json"

    if [ ! -d "$ZED_SETTINGS_DIR" ]; then
      $DRY_RUN_CMD mkdir -p "$ZED_SETTINGS_DIR"
    fi

    if [ ! -f "$ZED_SETTINGS_FILE" ]; then
      $DRY_RUN_CMD cp ${./defaultSettings.json} "$ZED_SETTINGS_FILE"
    fi
  '';
}
