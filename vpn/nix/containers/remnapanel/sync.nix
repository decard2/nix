# Remnawave API synchronization service
{
  pkgs,
  remnawave_api_token,
  ...
}:

let
  syncScript = pkgs.writers.writePython3Bin "remnawave-sync" {
    libraries = [ pkgs.python3Packages.requests ];
  } (builtins.readFile ./sync.py);
in
{
  systemd.services.remnawave-sync = {
    description = "Sync declarative config to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
    ];
    wants = [ "podman-remnawave-backend.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
    };

    environment = {
      REMNAWAVE_API_TOKEN = remnawave_api_token;
      REMNAWAVE_API_URL = "https://rolder.net/api";
      REMNAWAVE_CONFIGS_DIR = "${./configs}";
    };

    path = [ pkgs.systemd ];

    script = ''
      ${syncScript}/bin/remnawave-sync --apply
    '';
  };
}
