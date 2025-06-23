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
    echo "  -h, --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 frankfurt 37.221.125.150"
    echo "  $0 frankfurt 37.221.125.150 mypassword123"
    echo "  $0 -u root -p 2222 frankfurt 37.221.125.150 mypassword123"
    echo ""
    echo "Notes:"
    echo "  - Password is only used for SSH connection during installation"
    echo "  - User password for installed system is configured in flake.nix"
    echo "  - Each hostname must have its own configuration in flake.nix"
}

# Parse arguments
USER="root"
PORT="22"
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

# Get password if not provided
if [[ -z "$PASSWORD" ]]; then
    echo -e "${YELLOW}Enter password for SSH connection during installation:${NC}"
    read -s PASSWORD
    if [[ -z "$PASSWORD" ]]; then
        echo -e "${RED}❌ Password cannot be empty${NC}"
        exit 1
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

# Check if SSH key exists
if [[ ! -f ~/.ssh/id_rsa && ! -f ~/.ssh/id_ed25519 ]]; then
    echo -e "${RED}❌ No SSH key found. Please generate one first:${NC}"
    echo "ssh-keygen -t ed25519 -C 'your_email@example.com'"
    exit 1
fi

# Clean up any existing SSH keys for this host
echo -e "${YELLOW}Cleaning up existing SSH host keys...${NC}"
ssh-keygen -R "$TARGET_IP" 2>/dev/null || true
ssh-keygen -R "[$TARGET_IP]:$PORT" 2>/dev/null || true

# Test SSH connection with password
echo -e "${YELLOW}Testing SSH connection...${NC}"
export SSHPASS="$PASSWORD"
SSH_OPTIONS="-o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
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

echo -e "${GREEN}✅ SSH connection successful${NC}"

# Check target system
echo -e "${YELLOW}Checking target system...${NC}"
TARGET_INFO=$(sshpass -e ssh $SSH_OPTIONS -p "$PORT" "$TARGET_HOST" "uname -a && lsblk")
echo "$TARGET_INFO"
echo ""

# Check flake
echo -e "${YELLOW}Validating flake configuration...${NC}"
nix flake check

echo -e "${GREEN}✅ Flake configuration valid${NC}"

# Proceeding with automated installation
echo -e "${GREEN}🚀 Proceeding with automated installation...${NC}"
echo "Hostname: $HOSTNAME"
echo "Target: $TARGET_HOST:$PORT"
echo ""

# Use hostname-specific hardware configuration
HARDWARE_CONFIG="hardware/${HOSTNAME}.nix"
echo -e "${YELLOW}Using hardware config: $HARDWARE_CONFIG${NC}"

# Create hardware directory if it doesn't exist
mkdir -p hardware

# Run nixos-anywhere
echo -e "${GREEN}🚀 Starting NixOS installation...${NC}"
export SSHPASS="$PASSWORD"
nix run github:nix-community/nixos-anywhere -- \
    --flake ".#$FLAKE_CONFIG" \
    --target-host "$TARGET_HOST" \
    --ssh-port "$PORT" \
    --env-password \
    --ssh-option "StrictHostKeyChecking=no" \
    --ssh-option "UserKnownHostsFile=/dev/null" \
    --ssh-option "LogLevel=ERROR" \
    --generate-hardware-config nixos-generate-config ./$HARDWARE_CONFIG

# Hardware configuration is generated automatically by nixos-anywhere
echo -e "${GREEN}✅ Hardware configuration generated by nixos-anywhere${NC}"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo ""
    echo "Your server is now running NixOS!"
    echo "Hostname: $HOSTNAME"
    echo "You can connect with:"
    echo "  ssh -p 4444 rolder@$TARGET_IP"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "- Hardware configuration generated: ./$HARDWARE_CONFIG"
    echo "- The system will reboot automatically"
    echo "- SSH password authentication is enabled"
    echo "- Use the password configured in flake.nix"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Wait for reboot to complete"
    echo "2. Test connection: ssh -p 4444 rolder@$TARGET_IP"
    echo "3. Commit changes: git add . && git commit -m 'Add hardware config for $HOSTNAME'"
else
    echo -e "${RED}❌ Installation failed${NC}"
    exit 1
fi
