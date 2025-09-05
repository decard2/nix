#!/usr/bin/env bash

# SSH Diagnostic and Test Script
# Usage: ./debug-ssh.sh [hostname] [port] [username]
# Without args: runs local diagnostics
# With args: tests remote connection

set -e

HOSTNAME=${1:-""}
PORT=${2:-"22"}
USERNAME=${3:-"rolder"}

echo "=== SSH Diagnostic and Test Script ==="
echo "Date: $(date)"

if [ -n "$HOSTNAME" ]; then
    echo "Mode: Remote connection test to $USERNAME@$HOSTNAME:$PORT"
else
    echo "Mode: Local system diagnostics"
fi
echo

# Local diagnostics (always run)
echo "=== Local System Diagnostics ==="

# Check SSH service status
echo "--- SSH Service Status ---"
systemctl status sshd --no-pager -l || echo "SSH service status check failed"
echo

# Check SSH configuration
echo "--- SSH Configuration ---"
echo "SSH ports listening:"
ss -tlnp | grep sshd || echo "No SSH ports found"
echo

echo "SSH config summary:"
sshd -T | grep -E "(Port|PasswordAuthentication|PubkeyAuthentication|PermitRootLogin|AllowUsers|LogLevel)" || echo "Config test failed"
echo

# Check user configuration
echo "--- User Configuration ---"
echo "User rolder:"
id rolder 2>/dev/null || echo "User rolder not found"
echo

echo "User rolder groups:"
groups rolder 2>/dev/null || echo "Cannot get groups for rolder"
echo

echo "SSH keys for rolder:"
if [ -f /home/rolder/.ssh/authorized_keys ]; then
    echo "Authorized keys file exists ($(wc -l < /home/rolder/.ssh/authorized_keys) keys)"
    echo "Key fingerprints:"
    ssh-keygen -lf /home/rolder/.ssh/authorized_keys || echo "Cannot read key fingerprints"
else
    echo "No authorized_keys file found"
fi
echo

# Check Google OS Login status
echo "--- Google OS Login Status ---"
if systemctl is-active google-oslogin-cache.service >/dev/null 2>&1; then
    echo "Google OS Login is active:"
    systemctl status google-oslogin-cache.service --no-pager -l
else
    echo "Google OS Login service not found or inactive"
fi
echo

# Network information
echo "--- Network Information ---"
echo "Network interfaces with IPs:"
ip addr show | grep -E "(inet|UP|DOWN)" || echo "Cannot get network info"
echo

echo "SSH ports open:"
ss -tlnp | grep -E ":(22|4444)" || echo "No SSH ports found open"
echo

# Recent SSH logs
echo "--- Recent SSH Logs ---"
echo "Last 20 SSH log entries:"
journalctl -u sshd -n 20 --no-pager || echo "Cannot read SSH logs"
echo

# Firewall status
echo "--- Firewall Status ---"
echo "Open ports:"
ss -tlnp | grep -E ":(22|4444|2222|443)" || echo "Cannot get port info"
echo

# SSH config test
echo "--- SSH Configuration Test ---"
sshd -t && echo "✓ SSH config is valid" || echo "✗ SSH config has errors"
echo

# Remote connection tests (if hostname provided)
if [ -n "$HOSTNAME" ]; then
    echo "=== Remote Connection Tests ==="

    # Test 1: Network connectivity
    echo "--- Test 1: Network Connectivity ---"
    if timeout 5 nc -z "$HOSTNAME" "$PORT" 2>/dev/null; then
        echo "✓ Port $PORT is reachable on $HOSTNAME"
    else
        echo "✗ Port $PORT is NOT reachable on $HOSTNAME"
        exit 1
    fi
    echo

    # Test 2: SSH banner
    echo "--- Test 2: SSH Banner ---"
    timeout 10 nc "$HOSTNAME" "$PORT" <<< "" 2>/dev/null | head -1 || echo "No SSH banner received"
    echo

    # Test 3: SSH key authentication
    echo "--- Test 3: SSH Key Authentication ---"
    if ssh -o BatchMode=yes \
           -o ConnectTimeout=10 \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -o PasswordAuthentication=no \
           -o PubkeyAuthentication=yes \
           -p "$PORT" \
           "$USERNAME@$HOSTNAME" \
           "echo 'Key auth successful'; whoami; id" 2>/dev/null; then
        echo "✓ Key authentication successful"
    else
        echo "✗ Key authentication failed"
    fi
    echo

    # Test 4: Verbose connection debug
    echo "--- Test 4: Verbose SSH Debug (first 30 lines) ---"
    timeout 15 ssh -vvv \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o BatchMode=yes \
        -p "$PORT" \
        "$USERNAME@$HOSTNAME" \
        "echo 'Debug connection successful'" 2>&1 | head -30 || echo "Debug connection failed"
    echo

    # Test 5: Local SSH key info
    echo "--- Test 5: Local SSH Keys ---"
    for key_file in ~/.ssh/id_rsa.pub ~/.ssh/id_ed25519.pub ~/.ssh/id_ecdsa.pub; do
        if [ -f "$key_file" ]; then
            echo "Found key: $key_file"
            echo "Fingerprint: $(ssh-keygen -lf "$key_file")"
            echo
        fi
    done

    if ! ls ~/.ssh/*.pub >/dev/null 2>&1; then
        echo "No SSH public keys found in ~/.ssh/"
    fi
fi

echo "=== Diagnostic Complete ==="
if [ -n "$HOSTNAME" ]; then
    echo "If connection failed, check:"
    echo "1. Network connectivity to $HOSTNAME:$PORT"
    echo "2. SSH service running on remote host"
    echo "3. SSH keys match between local and remote"
    echo "4. User permissions and SSH config on remote"
else
    echo "Local diagnostics complete. To test remote connection:"
    echo "  $0 <hostname> [port] [username]"
fi
