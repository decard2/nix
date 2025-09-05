#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${GREEN}🚀 NixOS Anywhere Installation Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] HOSTNAME TARGET_IP [PASSWORD]"
    echo ""
    echo "Arguments:"
    echo "  HOSTNAME         Hostname for the server (e.g., warsaw, berlin)"
    echo "  TARGET_IP        Target server IP address"
    echo "  PASSWORD         Password for SSH connection during installation (optional, will prompt if not provided)"
    echo ""
    echo "Options:"
    echo "  -u, --user USER     SSH user (default: root)"
    echo "  -p, --port PORT     SSH port for installation (default: 22)"
    echo "  -k, --ssh-key PATH  SSH private key path (for GCP OS Login)"
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  # Traditional password auth:"
    echo "  $0 frankfurt 37.221.125.150"
    echo "  $0 frankfurt 37.221.125.150 mypassword123"
    echo ""
    echo "  # GCP OS Login with SSH key:"
    echo "  $0 -u admin_decard_rolder_dev -k ~/.ssh/rolder-gcp stockholm 34.51.201.70"
    echo ""
    echo "Notes:"
    echo "  - Password is only used for SSH connection during installation"
    echo "  - User password for installed system is configured in flake.nix"
    echo "  - Each hostname must have its own configuration in flake.nix"
    echo "  - For GCP OS Login, use -k option and appropriate username format"
}

# Parse arguments
USER="root"
PORT="22"
SSH_KEY=""
HOSTNAME=""
TARGET_IP=""
PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -k|--ssh-key)
            SSH_KEY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$HOSTNAME" ]]; then
                HOSTNAME="$1"
            elif [[ -z "$TARGET_IP" ]]; then
                TARGET_IP="$1"
            elif [[ -z "$PASSWORD" ]]; then
                PASSWORD="$1"
            else
                echo -e "${RED}❌ Too many arguments${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$HOSTNAME" || -z "$TARGET_IP" ]]; then
    echo -e "${RED}❌ Missing required arguments${NC}"
    show_help
    exit 1
fi

# Validate SSH authentication method
if [[ -n "$SSH_KEY" ]]; then
    # SSH key authentication
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${RED}❌ SSH key file not found: $SSH_KEY${NC}"
        exit 1
    fi
    # Expand tilde if present
    SSH_KEY=$(eval echo "$SSH_KEY")
    AUTH_METHOD="key"
    echo -e "${GREEN}Using SSH key authentication: $SSH_KEY${NC}"
else
    # Password authentication
    AUTH_METHOD="password"
    if [[ -z "$PASSWORD" ]]; then
        echo -e "${YELLOW}Enter password for SSH connection during installation:${NC}"
        read -s PASSWORD
        if [[ -z "$PASSWORD" ]]; then
            echo -e "${RED}❌ Password cannot be empty${NC}"
            exit 1
        fi
    fi
fi



# Check if specific configuration exists
if nix flake show 2>/dev/null | grep -q "$HOSTNAME"; then
    FLAKE_CONFIG="$HOSTNAME"
    echo -e "${GREEN}Using configuration for $HOSTNAME${NC}"
else
    echo -e "${RED}❌ No configuration found for hostname '$HOSTNAME'${NC}"
    echo "Available configurations:"
    nix flake show 2>/dev/null | grep "└───" | cut -d' ' -f2 || echo "  (unable to list configurations)"
    exit 1
fi

TARGET_HOST="$USER@$TARGET_IP"

echo -e "${GREEN}🚀 NixOS Anywhere Installation${NC}"
echo "Hostname: $HOSTNAME"
echo "Config: $FLAKE_CONFIG"
echo "Target: $TARGET_HOST:$PORT"
echo ""

# Check SSH key for password authentication only
if [[ "$AUTH_METHOD" == "password" ]]; then
    if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_ed25519 ]]; then
        echo -e "${RED}❌ No SSH key found. Please generate one first:${NC}"
        echo "ssh-keygen -t ed25519 -C 'your_email@example.com'"
        exit 1
    fi
fi

# Clean up any existing SSH keys for this host
echo -e "${YELLOW}Cleaning up existing SSH host keys...${NC}"
ssh-keygen -R "$TARGET_IP" 2>/dev/null || true
ssh-keygen -R "[$TARGET_IP]:$PORT" 2>/dev/null || true

# Test SSH connection
echo -e "${YELLOW}Testing SSH connection...${NC}"
SSH_OPTIONS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

if [[ "$AUTH_METHOD" == "key" ]]; then
    # SSH key authentication
    SSH_OPTIONS="$SSH_OPTIONS -i $SSH_KEY"
    if ! ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" exit 2>/dev/null; then
        echo -e "${RED}❌ Cannot connect to $TARGET_HOST via SSH with key${NC}"
        echo "Make sure:"
        echo "1. Server is accessible"
        echo "2. SSH key is correct and has proper permissions"
        echo "3. SSH service is running on port $PORT"
        echo "4. OS Login is configured (for GCP)"
        echo ""
        echo -e "${YELLOW}Note: Using port $PORT for installation${NC}"
        echo -e "${YELLOW}After installation, SSH will be on port 4444${NC}"
        exit 1
    fi
else
    # Password authentication
    export SSHPASS="$PASSWORD"
    if ! sshpass -e ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" exit 2>/dev/null; then
        echo -e "${RED}❌ Cannot connect to $TARGET_HOST via SSH${NC}"
        echo "Make sure:"
        echo "1. Server is accessible"
        echo "2. SSH password is correct"
        echo "3. SSH service is running on port $PORT"
        echo ""
        echo -e "${YELLOW}Note: Using port $PORT for installation${NC}"
        echo -e "${YELLOW}After installation, SSH will be on port 4444${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ SSH connection successful${NC}"

# Check target system
echo -e "${YELLOW}Checking target system...${NC}"
if [[ "$AUTH_METHOD" == "key" ]]; then
    TARGET_INFO=$(ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" "uname -a && lsblk")
else
    TARGET_INFO=$(sshpass -e ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" "uname -a && lsblk")
fi
echo "$TARGET_INFO"
echo ""

# For SSH key authentication, temporarily enable root access
if [[ "$AUTH_METHOD" == "key" ]]; then
    echo -e "${YELLOW}Setting up temporary root access for installation...${NC}"

    # Generate a temporary password for root
    TEMP_ROOT_PASSWORD="nixos-install-$(date +%s)"

    # Set up root access: password + SSH key + enable root login
    if ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" "
        set -e
        # Set root password
        echo 'root:$TEMP_ROOT_PASSWORD' | sudo chpasswd
        echo 'Root password set'

        # Copy SSH key to root's authorized_keys
        sudo mkdir -p /root/.ssh
        sudo chmod 700 /root/.ssh
        cat ~/.ssh/authorized_keys | sudo tee /root/.ssh/authorized_keys > /dev/null
        sudo chmod 600 /root/.ssh/authorized_keys
        echo 'SSH keys copied to root'

        # Configure SSH for root access
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        sudo sed -i 's/^.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        sudo sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sudo sed -i 's/^.*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
        echo 'SSH config updated'

        # Restart SSH service
        sudo systemctl restart ssh
        echo 'SSH service restarted'

        # Test root connection
        echo 'Testing root access...'
    "; then
        echo -e "${GREEN}✅ Temporary root access configured (password + SSH key)${NC}"

        # Test root connection with password
        echo -e "${YELLOW}Testing root connection...${NC}"
        TARGET_IP=$(echo "$TARGET_HOST" | cut -d'@' -f2)
        export SSHPASS="$TEMP_ROOT_PASSWORD"
        if sshpass -e ssh $SSH_OPTIONS -p "$PORT" "root@$TARGET_IP" "echo 'Root access working'" 2>/dev/null; then
            echo -e "${GREEN}✅ Root password authentication working${NC}"
        else
            echo -e "${YELLOW}⚠️  Root password auth failed, nixos-anywhere will try SSH keys${NC}"
        fi

        # Set variables for nixos-anywhere
        TARGET_HOST_FOR_INSTALL="root@$TARGET_IP"
        USE_ENV_PASSWORD="--env-password"
    else
        echo -e "${RED}❌ Failed to configure temporary root access${NC}"
        echo "Make sure your user has passwordless sudo privileges"
        exit 1
    fi
else
    TARGET_HOST_FOR_INSTALL="$TARGET_HOST"
    USE_ENV_PASSWORD="--env-password"
fi

# Check flake
echo -e "${YELLOW}Validating flake configuration...${NC}"
nix flake check

echo -e "${GREEN}✅ Flake configuration valid${NC}"

# Proceeding with automated installation
echo -e "${GREEN}🚀 Proceeding with automated installation...${NC}"
echo "Hostname: $HOSTNAME"
echo "Target: $TARGET_HOST:$PORT"
echo ""



# Run nixos-anywhere
echo -e "${GREEN}🚀 Starting NixOS installation...${NC}"

# Use temporary root access for installation
nix run github:nix-community/nixos-anywhere -- \
    --flake ".#$FLAKE_CONFIG" \
    --target-host "$TARGET_HOST_FOR_INSTALL" \
    --ssh-port "$PORT" \
    $USE_ENV_PASSWORD \
    --ssh-option "StrictHostKeyChecking=no" \
    --ssh-option "UserKnownHostsFile=/dev/null" \
    --ssh-option "LogLevel=ERROR"



if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo ""
    echo "Your server is now running NixOS!"
    echo "Hostname: $HOSTNAME"

    if [[ "$AUTH_METHOD" == "key" ]]; then
        echo ""
        echo -e "${GREEN}Connection options:${NC}"
        echo "1. Via Google OS Login (recommended):"
        echo "   ssh -p 4444 -i ~/.ssh/rolder-gcp admin_decard_rolder_dev@$TARGET_IP"
        echo ""
        echo "2. Via rolder user (with your SSH key):"
        echo "   ssh -p 4444 -i ~/.ssh/rolder-gcp rolder@$TARGET_IP"
        echo ""
        echo -e "${GREEN}Remote management:${NC}"
        echo "NIX_SSHOPTS=\"-p 4444 -i ~/.ssh/rolder-gcp\" nixos-rebuild switch --flake .#$HOSTNAME --target-host admin_decard_rolder_dev@$TARGET_IP"
    else
        echo "You can connect with:"
        echo "  ssh -p 4444 rolder@$TARGET_IP"
        echo ""
        echo -e "${YELLOW}Important:${NC}"
        echo "- SSH password authentication is enabled"
        echo "- Use the password configured in flake.nix"
    fi

    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "- The system will reboot automatically"
    echo "- Google OS Login is enabled for GCP features"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Wait for reboot to complete (2-3 minutes)"
    echo "2. Test the connection using one of the methods above"

else
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi
