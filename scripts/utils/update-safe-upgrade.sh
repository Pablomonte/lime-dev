#!/bin/bash
#
# Simple safe-upgrade updater for legacy routers (No SCP/SFTP support)
# Downloads and transfers latest safe-upgrade script only
#

set -e

ROUTER_IP="${1:-thisnode.info}"
SAFE_UPGRADE_URL="https://raw.githubusercontent.com/libremesh/lime-packages/refs/heads/master/packages/safe-upgrade/files/usr/sbin/safe-upgrade"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating safe-upgrade script on router: $ROUTER_IP"
echo "Note: Using alternative transfer methods (SCP/SFTP not available)"

# Download latest safe-upgrade
echo "Downloading latest safe-upgrade..."
wget -q -O /tmp/safe-upgrade "$SAFE_UPGRADE_URL"
chmod +x /tmp/safe-upgrade

# Backup existing safe-upgrade on router
echo "Backing up existing safe-upgrade..."
ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
    "cp /usr/sbin/safe-upgrade /usr/sbin/safe-upgrade.backup 2>/dev/null || echo 'No existing safe-upgrade to backup'"

# Transfer to router using alternative methods
echo "Transferring to router..."
if "$SCRIPT_DIR/../transfer-to-legacy-router.sh" "$ROUTER_IP" "/tmp/safe-upgrade" "/usr/sbin/safe-upgrade"; then
    echo "Transfer successful!"
else
    echo "Transfer failed, trying direct base64 method..."
    
    # Fallback method
    b64_content=$(base64 /tmp/safe-upgrade)
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "echo '$b64_content' | base64 -d > /usr/sbin/safe-upgrade 2>/dev/null || echo '$b64_content' | busybox base64 -d > /usr/sbin/safe-upgrade"; then
        echo "Fallback transfer successful!"
    else
        echo "❌ All transfer methods failed"
        rm -f /tmp/safe-upgrade
        exit 1
    fi
fi

# Make executable
echo "Installing on router..."
ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
    "chmod +x /usr/sbin/safe-upgrade && echo 'safe-upgrade updated successfully'"

# Cleanup
rm -f /tmp/safe-upgrade

echo "✅ safe-upgrade script updated on router $ROUTER_IP"
echo ""
echo "Usage:"
echo "  ssh -oHostKeyAlgorithms=+ssh-rsa root@$ROUTER_IP"
echo "  safe-upgrade -n  # Non-interactive upgrade"
echo ""
echo "To restore backup if needed:"
echo "  ssh -oHostKeyAlgorithms=+ssh-rsa root@$ROUTER_IP"
echo "  mv /usr/sbin/safe-upgrade.backup /usr/sbin/safe-upgrade"