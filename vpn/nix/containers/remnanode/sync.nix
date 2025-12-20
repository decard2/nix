# Remnanode certificate synchronization service
{
  pkgs,
  remnawave_api_token,
  ...
}:

{
  # Sync certificate from Remnawave Panel
  systemd.services.remnanode-certificate-sync = {
    description = "Sync certificate from Remnawave Panel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };

    script = ''
      echo "Syncing certificate from Remnawave Panel..."

      # Wait for Panel API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave Panel API to be available... ($i/30)"
        sleep 10
      done

      # Get certificate from Panel API
      CERT_RESPONSE=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/keygen" \
        -H "Authorization: Bearer ${remnawave_api_token}" \
        -H "Content-Type: application/json")

      if [ $? -eq 0 ]; then
        # Extract certificate from response
        CERT_DATA=$(echo "$CERT_RESPONSE" | ${pkgs.jq}/bin/jq -r '.response.pubKey')

        if [ "$CERT_DATA" != "null" ] && [ ! -z "$CERT_DATA" ]; then
          # Write certificate to file
          echo "$CERT_DATA" > /opt/remnanode/node-certificate.txt
          echo "Certificate successfully synced from Remnawave Panel"
        else
          echo "Warning: Invalid certificate data received from Panel"
          exit 1
        fi
      else
        echo "Warning: Failed to sync certificate from Remnawave Panel"
        exit 1
      fi
    '';
  };

  # Create environment file with certificate for container
  systemd.services.remnanode-create-env-file = {
    description = "Create node environment file with certificate";
    after = [ "remnanode-certificate-sync.service" ];
    wants = [ "remnanode-certificate-sync.service" ];
    before = [ "podman-remnanode.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo "SECRET_KEY=$(cat /opt/remnanode/node-certificate.txt)" > /opt/remnanode/node-certificate.env
      echo "Node environment file created successfully"
    '';
  };

}
