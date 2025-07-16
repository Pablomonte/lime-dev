#!/bin/bash
#
# Hex Chunked File Transfer for Legacy LibreRouter
# Transfers files to routers without SCP/SFTP support using hex encoding
# Specifically designed for LibreRouter v1 with pre-1.5 firmware
#

set -e

ROUTER_IP="${1:-thisnode.info}"
SOURCE_FILE="$2"
DEST_PATH="${3:-/tmp/$(basename "$2")}"
ROUTER_PASSWORD="${ROUTER_PASSWORD:-toorlibre1}"

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

usage() {
    cat << EOF
Hex Chunked File Transfer for Legacy LibreRouter

Usage: $0 <router_ip> <source_file> [destination_path]

Arguments:
    router_ip        Router IP address or hostname
    source_file      Local file to transfer
    destination_path Target path on router (default: /tmp/filename)

Environment Variables:
    ROUTER_PASSWORD  SSH password (default: toorlibre1)

Examples:
    $0 thisnode.info safe-upgrade /usr/sbin/safe-upgrade
    $0 10.13.0.1 firmware.bin /tmp/firmware.bin
    ROUTER_PASSWORD=mypass $0 10.13.0.1 config.tar.gz

This script uses chunked hex encoding to transfer files via SSH.
Works with legacy LibreRouter v1 that lacks SCP/SFTP and base64 support.
Uses only hexdump (available on all busybox systems) for reliable transfer.

EOF
}

# Check if help requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ $# -lt 2 ]]; then
    usage
    exit 0
fi

# Validate inputs
if [[ ! -f "$SOURCE_FILE" ]]; then
    print_error "Source file not found: $SOURCE_FILE"
    exit 1
fi

# SSH control socket for connection multiplexing
SSH_CONTROL_PATH="/tmp/ssh_control_${ROUTER_IP}_$$"

# SSH helper function with password support and connection multiplexing
ssh_cmd() {
    sshpass -p "$ROUTER_PASSWORD" ssh \
        -oHostKeyAlgorithms=+ssh-rsa \
        -oStrictHostKeyChecking=no \
        -oUserKnownHostsFile=/dev/null \
        -oPasswordAuthentication=yes \
        -oPubkeyAuthentication=no \
        -oKbdInteractiveAuthentication=no \
        -oPreferredAuthentications=password \
        -oConnectTimeout=10 \
        -oControlMaster=auto \
        -oControlPath="$SSH_CONTROL_PATH" \
        -oControlPersist=60s \
        root@"$ROUTER_IP" "$@"
}

# Cleanup function for SSH control socket
cleanup_ssh() {
    if [[ -S "$SSH_CONTROL_PATH" ]]; then
        ssh -oControlPath="$SSH_CONTROL_PATH" -O exit root@"$ROUTER_IP" 2>/dev/null || true
        rm -f "$SSH_CONTROL_PATH" 2>/dev/null || true
    fi
}

test_connection() {
    print_info "Testing SSH connection to $ROUTER_IP..."
    
    if ssh_cmd "echo 'Connection OK'" >/dev/null 2>&1; then
        print_success "SSH connection established"
    else
        print_error "Cannot connect to router at $ROUTER_IP"
        print_info "Check password (current: $ROUTER_PASSWORD)"
        print_info "Override with: ROUTER_PASSWORD=yourpass $0"
        exit 1
    fi
}

transfer_file_hex_chunks() {
    local file_size=$(stat -c%s "$SOURCE_FILE")
    local chunk_size=512  # Small chunks for reliable transfer
    local batch_size=5    # Process 5 chunks per SSH call
    local chunks=$(( (file_size + chunk_size - 1) / chunk_size ))
    local batches=$(( (chunks + batch_size - 1) / batch_size ))
    
    print_info "File size: $file_size bytes"
    print_info "Transferring in $chunks chunks ($batch_size per batch, $batches total batches)..."
    
    # Clear destination file
    ssh_cmd "> '$DEST_PATH'"
    
    # Transfer file in batches of chunks
    for (( batch=0; batch<batches; batch++ )); do
        local start_chunk=$((batch * batch_size))
        local end_chunk=$(( (batch + 1) * batch_size ))
        if [[ $end_chunk -gt $chunks ]]; then
            end_chunk=$chunks
        fi
        
        print_info "Transferring batch $((batch+1))/$batches (chunks $((start_chunk+1))-$end_chunk)..."
        
        # Build compound command for this batch
        local batch_cmd=""
        for (( i=start_chunk; i<end_chunk; i++ )); do
            # Extract chunk and encode as hex
            local chunk_hex=$(dd if="$SOURCE_FILE" bs=$chunk_size skip=$i count=1 2>/dev/null | hexdump -ve '1/1 "%.2x"')
            
            # Add to batch command
            if [[ -n "$batch_cmd" ]]; then
                batch_cmd="$batch_cmd; echo -n '$chunk_hex' | sed 's/../\\\\x&/g' | printf '%b' \$(cat) >> '$DEST_PATH'"
            else
                batch_cmd="echo -n '$chunk_hex' | sed 's/../\\\\x&/g' | printf '%b' \$(cat) >> '$DEST_PATH'"
            fi
        done
        
        # Execute batch
        if ! ssh_cmd "$batch_cmd"; then
            print_error "Failed to transfer batch $((batch+1))"
            return 1
        fi
    done
    
    return 0
}

verify_transfer() {
    print_info "Verifying transfer..."
    local file_size=$(stat -c%s "$SOURCE_FILE")
    local remote_size=$(ssh_cmd "stat -c%s '$DEST_PATH' 2>/dev/null || wc -c < '$DEST_PATH' | tr -d ' '" 2>/dev/null || echo "0")
    
    if [[ "$remote_size" == "$file_size" ]]; then
        print_success "Transfer verified (size: $file_size bytes)"
        return 0
    else
        print_error "Size mismatch: local=$file_size, remote=$remote_size"
        return 1
    fi
}

main() {
    echo "Legacy Router Hex File Transfer"
    echo "=============================="
    print_info "Source: $SOURCE_FILE"
    print_info "Target: $ROUTER_IP:$DEST_PATH"
    echo
    
    # Setup cleanup trap
    trap cleanup_ssh EXIT
    
    # Test connection
    test_connection
    
    # Transfer file using hex chunks
    print_info "Using hex encoding method (hexdump + sed)"
    if transfer_file_hex_chunks; then
        print_success "File transferred successfully"
        
        # Verify transfer
        if verify_transfer; then
            print_success "File successfully transferred to $ROUTER_IP:$DEST_PATH"
            
            # Make executable if it's a script
            if [[ "$SOURCE_FILE" == *.sh ]] || [[ -x "$SOURCE_FILE" ]]; then
                print_info "Making file executable..."
                ssh_cmd "chmod +x '$DEST_PATH'"
            fi
        else
            exit 1
        fi
    else
        print_error "Transfer failed"
        exit 1
    fi
}

main "$@"