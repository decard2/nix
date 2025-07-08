# Remnawave API synchronization services
{
  pkgs,
  ...
}:

{
  # Sync xray configuration to Remnawave API
  systemd.services.remnawave-xray-sync = {
    description = "Sync xray configuration to Remnawave API";
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
      RestartSec = "10s";
    };

    script = ''
      echo "Syncing xray configuration to Remnawave API..."
      echo "Xray config path: ${./configs/xray.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Sync xray configuration
      if ${pkgs.curl}/bin/curl -X PUT "https://rolder.net/api/xray" \
        -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiNzMwYzc5ZmEtMzUxMC00N2EwLWJhNDYtYTQ5NGE4Y2E1ODdjIiwidXNlcm5hbWUiOm51bGwsInJvbGUiOiJBUEkiLCJpYXQiOjE3NTE5Nzc2NjYsImV4cCI6MTAzOTE4OTEyNjZ9.UBBiJ03SHTVmp1v_hDbQyn95SPcc-aZk8BKjyTj60cw" \
        -H "Content-Type: application/json" \
        -d @${./configs/xray.json} \
        --silent --show-error --fail; then
        echo "Xray configuration successfully synced to Remnawave API"
      else
        echo "Warning: Failed to sync xray configuration to Remnawave API"
        exit 1
      fi
    '';
  };

  # Future sync services can be added here:
  # - systemd.services.remnawave-hosts-sync
  # - systemd.services.remnawave-nodes-sync
  # - systemd.services.remnawave-users-sync
}
