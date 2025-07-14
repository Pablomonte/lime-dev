#!/bin/bash
#
# File Transfer to Legacy Router (No SCP/SFTP Support)
# Multiple methods for transferring files when SCP/SFTP are not available
#

set -e

ROUTER_IP="${1:-thisnode.info}"
SOURCE_FILE="$2"
DEST_PATH="${3:-/tmp/$(basename "$2")}"

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
File Transfer to Legacy Router (No SCP/SFTP Support)

Usage: $0 <router_ip> <source_file> [destination_path]

Arguments:
    router_ip        Router IP address or hostname
    source_file      Local file to transfer
    destination_path Target path on router (default: /tmp/filename)

Methods tried in order:
1. HTTP server + wget (if router has wget)
2. Base64 encoding via SSH
3. Direct hex encoding via SSH
4. Netcat transfer (if available)

Examples:
    $0 thisnode.info safe-upgrade /usr/sbin/safe-upgrade
    $0 192.168.1.1 firmware.bin /tmp/firmware.bin

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

test_ssh_connection() {
    print_info "Testing SSH connection to $ROUTER_IP..."
    
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oConnectTimeout=10 -oStrictHostKeyChecking=no \
           root@"$ROUTER_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
        print_success "SSH connection established"
        return 0
    else
        print_error "Cannot connect to router via SSH"
        return 1
    fi
}

check_router_capabilities() {
    print_info "Checking router capabilities..."
    
    # Check for wget
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "which wget >/dev/null 2>&1" 2>/dev/null; then
        print_success "Router has wget - HTTP method available"
        ROUTER_HAS_WGET=1
    else
        print_warning "Router doesn't have wget - HTTP method not available"
        ROUTER_HAS_WGET=0
    fi
    
    # Check for netcat
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "which nc >/dev/null 2>&1 || which netcat >/dev/null 2>&1" 2>/dev/null; then
        print_success "Router has netcat - NC method available"
        ROUTER_HAS_NC=1
    else
        print_warning "Router doesn't have netcat"
        ROUTER_HAS_NC=0
    fi
    
    # Check for base64
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "which base64 >/dev/null 2>&1" 2>/dev/null; then
        print_success "Router has base64 - Base64 method available"
        ROUTER_HAS_BASE64=1
    else
        print_warning "Router doesn't have base64 - will use hex method"
        ROUTER_HAS_BASE64=0
    fi
}

transfer_via_http() {
    print_info "Method 1: Attempting HTTP server + wget transfer..."
    
    if [[ $ROUTER_HAS_WGET -eq 0 ]]; then
        print_warning "Router doesn't have wget, skipping HTTP method"
        return 1
    fi
    
    local http_port=8765
    local filename=$(basename "$SOURCE_FILE")
    
    # Find available port
    while netstat -ln 2>/dev/null | grep -q ":$http_port "; do
        ((http_port++))
    done
    
    print_info "Starting HTTP server on port $http_port..."
    
    # Start simple HTTP server in background
    (cd "$(dirname "$SOURCE_FILE")" && python3 -m http.server $http_port >/dev/null 2>&1) &
    local server_pid=$!
    
    # Wait for server to start
    sleep 2
    
    # Get local IP that router can reach
    local local_ip
    if command -v ip >/dev/null; then
        local_ip=$(ip route get "$ROUTER_IP" | grep -oP 'src \K\S+' | head -1)
    else
        local_ip=$(hostname -I | awk '{print $1}')
    fi
    
    print_info "Server started at http://$local_ip:$http_port/"
    print_info "Downloading file on router..."
    
    # Download file on router
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "wget -q -O '$DEST_PATH' 'http://$local_ip:$http_port/$filename' && echo 'Download successful'"; then
        print_success "File transferred via HTTP"
        kill $server_pid 2>/dev/null
        return 0
    else
        print_error "HTTP transfer failed"
        kill $server_pid 2>/dev/null
        return 1
    fi
}

transfer_via_base64() {
    print_info "Method 2: Attempting base64 encoding transfer..."
    
    if [[ $ROUTER_HAS_BASE64 -eq 0 ]]; then
        print_warning "Router doesn't have base64, skipping base64 method"
        return 1
    fi
    
    print_info "Encoding file as base64..."
    local encoded_file="/tmp/transfer_base64_$$"
    base64 "$SOURCE_FILE" > "$encoded_file"
    
    print_info "Transferring base64 encoded file..."
    
    # Transfer base64 content via SSH
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "cat > '$DEST_PATH.b64'" < "$encoded_file"; then
        
        print_info "Decoding file on router..."
        if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
               "base64 -d '$DEST_PATH.b64' > '$DEST_PATH' && rm '$DEST_PATH.b64' && echo 'Decode successful'"; then
            print_success "File transferred via base64"
            rm -f "$encoded_file"
            return 0
        else
            print_error "Base64 decode failed"
        fi
    else
        print_error "Base64 transfer failed"
    fi
    
    rm -f "$encoded_file"
    return 1
}

transfer_via_hex() {
    print_info "Method 3: Attempting hex encoding transfer..."
    
    print_info "Encoding file as hex..."
    local hex_content=$(hexdump -ve '1/1 "%.2x"' "$SOURCE_FILE")
    
    print_info "Transferring hex encoded file..."
    
    # Transfer hex content and decode on router
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "echo '$hex_content' | sed 's/../\\\\x&/g' | xargs -0 printf > '$DEST_PATH' && echo 'Hex transfer successful'"; then
        print_success "File transferred via hex encoding"
        return 0
    else
        print_error "Hex transfer failed - file may be too large"
        return 1
    fi
}

transfer_via_chunks() {
    print_info "Method 4: Attempting chunked transfer via SSH..."
    
    local chunk_size=1024
    local total_size=$(stat -c%s "$SOURCE_FILE")
    local chunks=$((total_size / chunk_size + 1))
    
    print_info "File size: $total_size bytes, will transfer in $chunks chunks"
    
    # Clear destination file
    ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
        "> '$DEST_PATH'"
    
    # Transfer file in chunks
    local offset=0
    local chunk_num=1
    
    while [[ $offset -lt $total_size ]]; do
        print_info "Transferring chunk $chunk_num/$chunks..."
        
        # Extract chunk and encode as base64
        local chunk_b64=$(dd if="$SOURCE_FILE" bs=$chunk_size skip=$((offset / chunk_size)) count=1 2>/dev/null | base64 -w 0)
        
        # Append chunk to file on router
        if ! ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
               "echo '$chunk_b64' | base64 -d >> '$DEST_PATH'"; then
            print_error "Failed to transfer chunk $chunk_num"
            return 1
        fi
        
        offset=$((offset + chunk_size))
        ((chunk_num++))
    done
    
    print_success "File transferred via chunked method"
    return 0
}

verify_transfer() {
    print_info "Verifying file transfer..."
    
    # Check if file exists and has content
    if ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
           "test -f '$DEST_PATH' && test -s '$DEST_PATH'"; then
        
        # Get file sizes
        local local_size=$(stat -c%s "$SOURCE_FILE")
        local remote_size=$(ssh -oHostKeyAlgorithms=+ssh-rsa -oStrictHostKeyChecking=no root@"$ROUTER_IP" \
                           "stat -c%s '$DEST_PATH'" 2>/dev/null || echo "0")
        
        if [[ "$local_size" == "$remote_size" ]]; then
            print_success "File transfer verified (size: $local_size bytes)"
            return 0
        else
            print_error "File size mismatch: local=$local_size, remote=$remote_size"
            return 1
        fi
    else
        print_error "File not found or empty on router"
        return 1
    fi
}

main() {
    echo "Legacy Router File Transfer"
    echo "=========================="
    print_info "Source: $SOURCE_FILE"
    print_info "Target: $ROUTER_IP:$DEST_PATH"
    echo
    
    # Test SSH connection
    if ! test_ssh_connection; then
        exit 1
    fi
    
    # Check router capabilities
    check_router_capabilities
    echo
    
    # Try transfer methods in order of preference
    local transfer_success=0
    
    # Method 1: HTTP + wget
    if [[ $transfer_success -eq 0 ]]; then
        if transfer_via_http; then
            transfer_success=1
        fi
    fi
    
    # Method 2: Base64 encoding
    if [[ $transfer_success -eq 0 ]]; then
        if transfer_via_base64; then
            transfer_success=1
        fi
    fi
    
    # Method 3: Hex encoding (for small files)
    if [[ $transfer_success -eq 0 ]]; then
        local file_size=$(stat -c%s "$SOURCE_FILE")
        if [[ $file_size -lt 32768 ]]; then  # 32KB limit for hex
            if transfer_via_hex; then
                transfer_success=1
            fi
        else
            print_warning "File too large for hex encoding (${file_size} bytes > 32KB)"
        fi
    fi
    
    # Method 4: Chunked transfer
    if [[ $transfer_success -eq 0 ]] && [[ $ROUTER_HAS_BASE64 -eq 1 ]]; then
        if transfer_via_chunks; then
            transfer_success=1
        fi
    fi
    
    if [[ $transfer_success -eq 1 ]]; then
        verify_transfer
        print_success "File successfully transferred to $ROUTER_IP:$DEST_PATH"
    else
        print_error "All transfer methods failed"
        exit 1
    fi
}

main "$@"