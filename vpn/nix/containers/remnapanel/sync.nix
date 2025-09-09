# Remnawave API synchronization services
{
  pkgs,
  remnawave_api_token,
  ...
}:

{
  # Sync config profiles to Remnawave API
  systemd.services.remnawave-config-profiles-sync = {
    description = "Sync config profiles to Remnawave API";
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
      echo "Syncing config profiles to Remnawave API..."
      echo "Config profiles config path: ${./configs/config-profiles.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Process each config profile from config
      ${pkgs.jq}/bin/jq -c '.[]' ${./configs/config-profiles.json} | while read profile; do
        UUID=$(echo $profile | ${pkgs.jq}/bin/jq -r '.uuid')
        NAME=$(echo $profile | ${pkgs.jq}/bin/jq -r '.name')

        # Update existing config profile
        UPDATE_DATA=$(echo $profile | ${pkgs.jq}/bin/jq '{uuid: .uuid, config: .config}')

        if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/config-profiles" \
          -H "Authorization: Bearer ${remnawave_api_token}" \
          -H "Content-Type: application/json" \
          -d "$UPDATE_DATA" \
          --silent --show-error --fail; then
          echo "Config profile updated successfully: $NAME (UUID: $UUID)"
        else
          echo "Warning: Failed to update config profile: $NAME"
          exit 1
        fi
      done

      echo "Config profiles successfully synced to Remnawave API"
    '';
  };

  # Sync internal squads to Remnawave API
  systemd.services.remnawave-internal-squads-sync = {
    description = "Sync internal squads to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
      "remnawave-config-profiles-sync.service"
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
      echo "Syncing internal squads to Remnawave API..."
      echo "Internal squads config path: ${./configs/internal-squads.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Get existing internal squads
      EXISTING_SQUADS=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/internal-squads" \
        -H "Authorization: Bearer ${remnawave_api_token}" \
        -H "Content-Type: application/json")

      # Process each internal squad from config
      ${pkgs.jq}/bin/jq -c '.[]' ${./configs/internal-squads.json} | while read squad; do
        UUID=$(echo $squad | ${pkgs.jq}/bin/jq -r '.uuid')
        NAME=$(echo $squad | ${pkgs.jq}/bin/jq -r '.name')
        INBOUNDS=$(echo $squad | ${pkgs.jq}/bin/jq -r '.inbounds')

        # Check if squad exists
        EXISTING_UUID=$(echo "$EXISTING_SQUADS" | ${pkgs.jq}/bin/jq -r ".response.internalSquads[] | select(.uuid == \"$UUID\") | .uuid")

        if [ ! -z "$EXISTING_UUID" ] && [ "$EXISTING_UUID" != "null" ]; then
          # Update existing internal squad
          UPDATE_DATA=$(echo $squad | ${pkgs.jq}/bin/jq '{uuid: .uuid, inbounds: .inbounds}')
          if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/internal-squads" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_DATA" \
            --silent --show-error --fail; then
            echo "Internal squad updated successfully: $NAME (UUID: $UUID)"
          else
            echo "Warning: Failed to update internal squad: $NAME"
            exit 1
          fi
        else
          echo "Internal squad with UUID $UUID not found in API, skipping..."
        fi
      done

      echo "Internal squads successfully synced to Remnawave API"
    '';
  };

  # Sync hosts configuration to Remnawave API
  systemd.services.remnawave-hosts-sync = {
    description = "Sync hosts configuration to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
      "remnawave-config-profiles-sync.service"
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
      echo "Syncing hosts configuration to Remnawave API..."
      echo "Hosts config path: ${./configs/hosts.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Get existing hosts
      EXISTING_HOSTS=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/hosts" \
        -H "Authorization: Bearer ${remnawave_api_token}" \
        -H "Content-Type: application/json")

      # Process each host from config
      ${pkgs.jq}/bin/jq -c '.[]' ${./configs/hosts.json} | while read host; do
        ADDRESS=$(echo $host | ${pkgs.jq}/bin/jq -r '.address')
        PORT=$(echo $host | ${pkgs.jq}/bin/jq -r '.port')
        REMARK=$(echo $host | ${pkgs.jq}/bin/jq -r '.remark')

        # Find existing host by address+port
        EXISTING_UUID=$(echo "$EXISTING_HOSTS" | ${pkgs.jq}/bin/jq -r ".response[] | select(.address == \"$ADDRESS\" and .port == $PORT) | .uuid")

        if [ ! -z "$EXISTING_UUID" ] && [ "$EXISTING_UUID" != "null" ]; then
          # Update existing host
          UPDATE_DATA=$(echo $host | ${pkgs.jq}/bin/jq ". + {\"uuid\": \"$EXISTING_UUID\"}")
          if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/hosts" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_DATA" \
            --silent --show-error --fail; then
            echo "Host updated successfully: $REMARK ($ADDRESS:$PORT)"
          else
            echo "Warning: Failed to update host: $REMARK ($ADDRESS:$PORT)"
            exit 1
          fi
        else
          # Create new host
          if ${pkgs.curl}/bin/curl -X POST "https://rolder.net/api/hosts" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$host" \
            --silent --show-error --fail; then
            echo "Host created successfully: $REMARK ($ADDRESS:$PORT)"
          else
            echo "Warning: Failed to create host: $REMARK ($ADDRESS:$PORT)"
            exit 1
          fi
        fi
      done

      echo "Hosts configuration successfully synced to Remnawave API"
    '';
  };

  # Sync nodes configuration to Remnawave API
  systemd.services.remnawave-nodes-sync = {
    description = "Sync nodes configuration to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
      "remnawave-config-profiles-sync.service"
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
      echo "Syncing nodes configuration to Remnawave API..."
      echo "Nodes config path: ${./configs/nodes.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Get existing nodes
      EXISTING_NODES=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/nodes" \
        -H "Authorization: Bearer ${remnawave_api_token}" \
        -H "Content-Type: application/json")

      # Process each node from config
      ${pkgs.jq}/bin/jq -c '.[]' ${./configs/nodes.json} | while read node; do
        ADDRESS=$(echo $node | ${pkgs.jq}/bin/jq -r '.address')
        PORT=$(echo $node | ${pkgs.jq}/bin/jq -r '.port')
        NAME=$(echo $node | ${pkgs.jq}/bin/jq -r '.name')

        # Find existing node by address+port
        EXISTING_UUID=$(echo "$EXISTING_NODES" | ${pkgs.jq}/bin/jq -r ".response[] | select(.address == \"$ADDRESS\" and .port == $PORT) | .uuid")

        if [ ! -z "$EXISTING_UUID" ] && [ "$EXISTING_UUID" != "null" ]; then
          # Update existing node
          UPDATE_DATA=$(echo $node | ${pkgs.jq}/bin/jq ". + {\"uuid\": \"$EXISTING_UUID\"}")
          if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/nodes" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_DATA" \
            --silent --show-error --fail; then
            echo "Node updated successfully: $NAME ($ADDRESS:$PORT)"
          else
            echo "Warning: Failed to update node: $NAME ($ADDRESS:$PORT)"
            exit 1
          fi
        else
          # Create new node
          if ${pkgs.curl}/bin/curl -X POST "https://rolder.net/api/nodes" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$node" \
            --silent --show-error --fail; then
            echo "Node created successfully: $NAME ($ADDRESS:$PORT)"
          else
            echo "Warning: Failed to create node: $NAME ($ADDRESS:$PORT)"
            exit 1
          fi
        fi
      done

      echo "Nodes configuration successfully synced to Remnawave API"
    '';
  };

  # Sync users configuration to Remnawave API
  systemd.services.remnawave-users-sync = {
    description = "Sync users configuration to Remnawave API";
    after = [
      "network.target"
      "podman-remnawave-backend.service"
      "remnawave-internal-squads-sync.service"
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
      echo "Syncing users configuration to Remnawave API..."
      echo "Users config path: ${./configs/users.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Get existing users
      EXISTING_USERS=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/users" \
        -H "Authorization: Bearer ${remnawave_api_token}" \
        -H "Content-Type: application/json")

      # Process each user from config
      ${pkgs.jq}/bin/jq -c '.[]' ${./configs/users.json} | while read user; do
        USERNAME=$(echo $user | ${pkgs.jq}/bin/jq -r '.username')

        # Find existing user by username
        EXISTING_UUID=$(echo "$EXISTING_USERS" | ${pkgs.jq}/bin/jq -r ".response.users[] | select(.username == \"$USERNAME\") | .uuid")

        if [ ! -z "$EXISTING_UUID" ] && [ "$EXISTING_UUID" != "null" ]; then
          # Update existing user
          UPDATE_DATA=$(echo $user | ${pkgs.jq}/bin/jq ". + {\"uuid\": \"$EXISTING_UUID\"}")
          if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/users" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$UPDATE_DATA" \
            --silent --show-error --fail; then
            echo "User updated successfully: $USERNAME (UUID: $EXISTING_UUID)"
          else
            echo "Warning: Failed to update user: $USERNAME"
            exit 1
          fi
        else
          # Create new user
          if ${pkgs.curl}/bin/curl -X POST "https://rolder.net/api/users" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$user" \
            --silent --show-error --fail; then
            echo "User created successfully: $USERNAME"
          else
            echo "Warning: Failed to create user: $USERNAME"
            exit 1
          fi
        fi
      done

      echo "Users configuration successfully synced to Remnawave API"
    '';
  };

  # Sync additional settings to Remnawave API
  systemd.services.remnawave-additional-settings-sync = {
    description = "Sync additional settings to Remnawave API";
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
      echo "Syncing additional settings to Remnawave API..."
      echo "Additional settings config path: ${./configs/additional-settings.json}"

      # Wait for API to be available
      for i in {1..30}; do
        if ${pkgs.curl}/bin/curl -s --connect-timeout 5 https://rolder.net/api/system/health > /dev/null; then
          break
        fi
        echo "Waiting for Remnawave API to be available... ($i/30)"
        sleep 10
      done

      # Sync subscription settings
      SUBSCRIPTION_SETTINGS=$(${pkgs.jq}/bin/jq -c '.subscriptionSettings' ${./configs/additional-settings.json})
      if [ "$SUBSCRIPTION_SETTINGS" != "null" ]; then
        # Get current subscription settings to obtain UUID
        CURRENT_SETTINGS=$(${pkgs.curl}/bin/curl -s "https://rolder.net/api/subscription-settings" \
          -H "Authorization: Bearer ${remnawave_api_token}" \
          -H "Content-Type: application/json")

        SUBSCRIPTION_UUID=$(echo "$CURRENT_SETTINGS" | ${pkgs.jq}/bin/jq -r '.response.uuid')

        if [ ! -z "$SUBSCRIPTION_UUID" ] && [ "$SUBSCRIPTION_UUID" != "null" ]; then
          # Add UUID to subscription settings
          SUBSCRIPTION_DATA=$(echo "$SUBSCRIPTION_SETTINGS" | ${pkgs.jq}/bin/jq ". + {\"uuid\": \"$SUBSCRIPTION_UUID\"}")

          if ${pkgs.curl}/bin/curl -X PATCH "https://rolder.net/api/subscription-settings" \
            -H "Authorization: Bearer ${remnawave_api_token}" \
            -H "Content-Type: application/json" \
            -d "$SUBSCRIPTION_DATA" \
            --silent --show-error --fail; then
            echo "Subscription settings successfully synced to Remnawave API"
          else
            echo "Warning: Failed to sync subscription settings to Remnawave API"
            exit 1
          fi
        else
          echo "Warning: Could not obtain subscription settings UUID"
          exit 1
        fi
      fi

      echo "Additional settings successfully synced to Remnawave API"
    '';
  };
}
