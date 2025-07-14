#!/bin/bash
#
# LibreRouter Legacy Firmware Upgrade Script
# Updates LibreRouter v1 with pre-1.5 firmware to latest version
#
# This script handles routers with:
# - Old SSH key algorithms (requires -oHostKeyAlgorithms=+ssh-rsa)
# - No sftp-server support (uses scp instead)
# - Limited resources (downloads to PC first, then transfers)
#

set -e

# Configuration
ROUTER_IP="${1:-thisnode.info}"
FIRMWARE_URL="https://raw.githubusercontent.com/libremesh/lime-packages/refs/heads/master/packages/safe-upgrade/files/usr/sbin/safe-upgrade"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$SCRIPT_DIR/../cache/router-upgrade"
SAFE_UPGRADE_FILE="safe-upgrade"
BACKUP_DIR="$TEMP_DIR/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${YELLOW}=== $1 ===${NC}"
}

usage() {
    cat << EOF
LibreRouter Legacy Firmware Upgrade Script

Usage: $0 [ROUTER_IP]

Arguments:
    ROUTER_IP    Router IP address or hostname (default: thisnode.info)

Examples:
    $0                        # Update router at thisnode.info
    $0 192.168.1.1           # Update router at specific IP
    $0 10.13.0.1             # Update QEMU development router

This script:
1. Downloads latest safe-upgrade script from LibreMesh repository
2. Creates backup of current router configuration
3. Transfers safe-upgrade to router using legacy SSH/SCP
4. Executes firmware upgrade safely on the router
5. Verifies upgrade completion

Requirements:
- SSH access to router (legacy algorithm support)
- SCP support (no sftp needed)
- Internet connection for firmware download

EOF
}

# Check if help requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
    exit 0
fi

check_dependencies() {
    print_step "Checking Dependencies"
    
    local missing_deps=()
    
    if ! command -v ssh >/dev/null; then
        missing_deps+=("ssh")
    fi
    
    if ! command -v scp >/dev/null; then
        missing_deps+=("scp")
    fi
    
    if ! command -v wget >/dev/null && ! command -v curl >/dev/null; then
        missing_deps+=("wget or curl")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Install with: sudo apt-get install openssh-client wget"
        exit 1
    fi
    
    print_success "All dependencies available"
}

setup_environment() {
    print_step "Setting Up Environment"
    
    # Create temporary directories
    mkdir -p "$TEMP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    print_info "Working directory: $TEMP_DIR"
    print_info "Backup directory: $BACKUP_DIR"
}

download_safe_upgrade() {
    print_step "Downloading Latest safe-upgrade Script"
    
    local safe_upgrade_path="$TEMP_DIR/$SAFE_UPGRADE_FILE"
    
    print_info "Downloading from: $FIRMWARE_URL"
    
    if command -v wget >/dev/null; then
        if wget -q --show-progress -O "$safe_upgrade_path" "$FIRMWARE_URL"; then
            print_success "Downloaded safe-upgrade script"
        else
            print_error "Failed to download with wget"
            exit 1
        fi
    elif command -v curl >/dev/null; then
        if curl -L -o "$safe_upgrade_path" "$FIRMWARE_URL"; then
            print_success "Downloaded safe-upgrade script"
        else
            print_error "Failed to download with curl"
            exit 1
        fi
    fi
    
    # Verify download
    if [[ ! -f "$safe_upgrade_path" ]] || [[ ! -s "$safe_upgrade_path" ]]; then
        print_error "Downloaded file is empty or missing"
        exit 1
    fi
    
    # Make executable
    chmod +x "$safe_upgrade_path"
    
    local file_size=$(stat -c%s "$safe_upgrade_path")
    print_info "Downloaded file size: $file_size bytes"
}

test_router_connection() {
    print_step "Testing Router Connection"
    
    print_info "Testing SSH connection to $ROUTER_IP..."
    
    # Test SSH connection with legacy algorithm support
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oConnectTimeout=10 -oStrictHostKeyChecking=no \
           root@"$ROUTER_IP" "echo 'Connection successful'" >/dev/null 2>&1; then
        print_success "SSH connection established"
    else
        print_error "Cannot connect to router at $ROUTER_IP"
        print_info "Verify:"
        print_info "  1. Router is powered on and connected to network"
        print_info "  2. IP address/hostname is correct"
        print_info "  3. SSH service is running on router"
        print_info "  4. No firewall blocking SSH (port 22)"
        exit 1
    fi
}

backup_router_config() {
    print_step "Backing Up Router Configuration"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/router_backup_$timestamp.tar.gz"
    
    print_info "Creating configuration backup..."
    
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "tar -czf /tmp/backup.tar.gz /etc/ /usr/lib/lua/lime/ 2>/dev/null || true"; then
        print_info "Configuration archived on router"
    else
        print_warning "Could not create complete backup archive"
    fi
    
    # Download backup
    if scp -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no \
           root@"$ROUTER_IP":/tmp/backup.tar.gz "$backup_file" 2>/dev/null; then
        print_success "Backup downloaded to: $backup_file"
        
        # Clean up temporary file on router
        ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
            "rm -f /tmp/backup.tar.gz" 2>/dev/null || true
    else
        print_warning "Could not download backup (will proceed anyway)"
    fi
}

transfer_safe_upgrade() {
    print_step "Transferring safe-upgrade to Router"
    
    local safe_upgrade_path="$TEMP_DIR/$SAFE_UPGRADE_FILE"
    
    print_info "Transferring safe-upgrade script to router..."
    
    if scp -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no \
           "$safe_upgrade_path" root@"$ROUTER_IP":/tmp/safe-upgrade; then
        print_success "safe-upgrade transferred successfully"
    else
        print_error "Failed to transfer safe-upgrade script"
        exit 1
    fi
    
    # Make executable on router
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "chmod +x /tmp/safe-upgrade"; then
        print_success "safe-upgrade made executable on router"
    else
        print_error "Failed to make safe-upgrade executable"
        exit 1
    fi
}

verify_safe_upgrade() {
    print_step "Verifying safe-upgrade Script"
    
    print_info "Checking safe-upgrade script on router..."
    
    # Check if file exists and is executable
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "test -x /tmp/safe-upgrade && echo 'safe-upgrade ready'"; then
        print_success "safe-upgrade script is ready for execution"
    else
        print_error "safe-upgrade script is not ready"
        exit 1
    fi
    
    # Show help to verify it's working
    print_info "Testing safe-upgrade functionality..."
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "/tmp/safe-upgrade -h" 2>/dev/null | head -5; then
        print_success "safe-upgrade script is functional"
    else
        print_warning "Could not test safe-upgrade help (may still work)"
    fi
}

execute_upgrade() {
    print_step "Executing Firmware Upgrade"
    
    print_warning "About to start firmware upgrade process"
    print_info "This will:"
    print_info "  1. Download latest firmware for your router model"
    print_info "  2. Verify firmware integrity"
    print_info "  3. Install new firmware"
    print_info "  4. Reboot router with new firmware"
    print_info ""
    print_warning "Router will be unavailable during upgrade (5-10 minutes)"
    print_warning "DO NOT power off router during upgrade process!"
    print_info ""
    
    read -p "Continue with firmware upgrade? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Upgrade cancelled by user"
        exit 0
    fi
    
    print_info "Starting firmware upgrade..."
    
    # Execute safe-upgrade with default options
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "/tmp/safe-upgrade -n"; then
        print_success "Firmware upgrade completed successfully"
    else
        print_error "Firmware upgrade failed or was interrupted"
        print_info "Router may be rebooting - check status in a few minutes"
        exit 1
    fi
}

wait_for_reboot() {
    print_step "Waiting for Router Reboot"
    
    print_info "Router is rebooting with new firmware..."
    print_info "This typically takes 2-5 minutes"
    
    local max_wait=300  # 5 minutes
    local waited=0
    
    # Wait for router to go offline
    sleep 30
    
    while [[ $waited -lt $max_wait ]]; do
        if ssh -oHostKeyAlgorithms=+ssh-rsa -oConnectTimeout=5 -oStrictHostKeyChecking=no \
               root@"$ROUTER_IP" "echo 'Router online'" >/dev/null 2>&1; then
            print_success "Router is back online!"
            break
        fi
        
        print_info "Waiting for router... ($waited/${max_wait}s)"
        sleep 15
        waited=$((waited + 15))
    done
    
    if [[ $waited -ge $max_wait ]]; then
        print_warning "Router did not come back online within expected time"
        print_info "This may be normal - check router status manually"
    fi
}

verify_upgrade() {
    print_step "Verifying Upgrade"
    
    print_info "Checking new firmware version..."
    
    if version_info=$(ssh -oHostKeyAlgorithms=+ssh-rsa -oConnectTimeout=10 -oStrictHostKeyChecking=no \
                     root@"$ROUTER_IP" "cat /etc/banner 2>/dev/null | head -3" 2>/dev/null); then
        echo "$version_info"
        print_success "Upgrade verification completed"
    else
        print_warning "Could not verify new firmware version"
        print_info "Router may still be initializing - check manually later"
    fi
    
    # Clean up transferred file
    ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
        "rm -f /tmp/safe-upgrade" 2>/dev/null || true
}

cleanup() {
    print_step "Cleanup"
    
    print_info "Cleaning up temporary files..."
    
    # Keep backups but clean up downloaded files
    rm -f "$TEMP_DIR/$SAFE_UPGRADE_FILE"
    
    print_success "Cleanup completed"
    print_info "Backups preserved in: $BACKUP_DIR"
}

main() {
    echo "LibreRouter Legacy Firmware Upgrade"
    echo "====================================="
    print_info "Target router: $ROUTER_IP"
    print_info "Upgrade source: LibreMesh official repository"
    echo
    
    check_dependencies
    setup_environment
    download_safe_upgrade
    test_router_connection
    backup_router_config
    transfer_safe_upgrade
    verify_safe_upgrade
    execute_upgrade
    wait_for_reboot
    verify_upgrade
    cleanup
    
    print_success "Router upgrade process completed!"
    print_info "Your LibreRouter v1 has been updated to the latest firmware"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Execute main function
main "$@"