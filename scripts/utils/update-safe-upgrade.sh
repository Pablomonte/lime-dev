#!/bin/bash
#
# Simple safe-upgrade updater for legacy routers
# Downloads and transfers latest safe-upgrade script only
#

set -e

ROUTER_IP="${1:-thisnode.info}"
SAFE_UPGRADE_URL="https://raw.githubusercontent.com/libremesh/lime-packages/refs/heads/master/packages/safe-upgrade/files/usr/sbin/safe-upgrade"

echo "Updating safe-upgrade script on router: $ROUTER_IP"

# Download latest safe-upgrade
echo "Downloading latest safe-upgrade..."
wget -q -O /tmp/safe-upgrade "$SAFE_UPGRADE_URL"
chmod +x /tmp/safe-upgrade

# Transfer to router
echo "Transferring to router..."
scp -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no \
    /tmp/safe-upgrade root@"$ROUTER_IP":/usr/sbin/safe-upgrade

# Make executable and backup old version
echo "Installing on router..."
ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
    "chmod +x /usr/sbin/safe-upgrade && echo 'safe-upgrade updated successfully'"

# Cleanup
rm -f /tmp/safe-upgrade

echo "✅ safe-upgrade script updated on router $ROUTER_IP"
echo "Now you can run: ssh -oHostKeyAlgorithms=+ssh-rsa root@$ROUTER_IP"
echo "Then execute: safe-upgrade -n"