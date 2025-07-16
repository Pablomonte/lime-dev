#!/usr/bin/env bash
#
# LibreMesh QEMU Management System
# Standalone QEMU management extracted from lime-app for lime-dev
# Original breakthrough implementation by fede654
#
# Usage: ./qemu-manager.sh {start|stop|restart|status|deploy|console|configs}
#

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration (defaults - can be overridden by image configs)
LIME_PACKAGES_DIR="${LIME_PACKAGES_DIR:-$SCRIPT_DIR/../../repos/lime-packages}"
QEMU_IP="10.13.0.1"
BRIDGE_IP="10.13.0.2"
BRIDGE_IFC="lime_br0"

# Source image configuration system
source "$SCRIPT_DIR/qemu-image-configs.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if QEMU is running
check_qemu_running() {
    if ! pgrep -f "qemu-system-x86_64" >/dev/null 2>&1; then
        return 1
    fi
    
    if ping -c 1 -W 1 "$QEMU_IP" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Initialize configuration arrays and auto-detect images
initialize_qemu_config() {
    AVAILABLE_CONFIGS=()
    
    if [ ! -d "$LIME_PACKAGES_DIR" ]; then
        print_error "lime-packages directory not found: $LIME_PACKAGES_DIR"
        print_error "Please ensure lime-packages repository is available"
        return 1
    fi
    
    # Auto-detect and validate image configuration
    auto_detect_image_config
    validate_image_config
    
    print_status "QEMU configuration initialized: $IMAGE_NAME"
    return 0
}

# Start QEMU using official method
start_qemu() {
    print_status "Starting LibreMesh QEMU..."
    
    if check_qemu_running; then
        print_warning "QEMU already running at $QEMU_IP"
        return 0
    fi
    
    if ! initialize_qemu_config; then
        return 1
    fi
    
    cd "$LIME_PACKAGES_DIR"
    
    print_status "Using official qemu_dev_start method..."
    print_status "This creates bridge $BRIDGE_IFC with IP $BRIDGE_IP"
    print_status "Telnet console will be available on port $TELNET_PORT"
    
    # Calculate node_id from telnet port (45400 -> 00, 45401 -> 01)
    local node_id="00"
    if [ "$TELNET_PORT" = "45401" ]; then
        node_id="01"
    fi
    
    # Start QEMU using the official script with image-specific configuration
    # Use screen session for console interaction (lime-app compatible naming)
    local screen_name="libremesh-${IMAGE_TYPE}"
    
    # Kill any existing screen session
    sudo screen -S "$screen_name" -X quit 2>/dev/null || true
    sleep 1
    
    # Start QEMU in a screen session (modified for virtio-net compatibility)
    sudo screen -dmS "$screen_name" bash -c "
        cd '$LIME_PACKAGES_DIR'
        
        # Create TAP interfaces if they don't exist
        for ifc in lime_tap${node_id}_0 lime_tap${node_id}_1 lime_tap${node_id}_2; do
            if [ ! -e \"/sys/class/net/\$ifc\" ]; then
                ip tuntap add name \"\$ifc\" mode tap
                ip link set \"\$ifc\" up
            fi
        done
        
        # Create bridge if it doesn't exist
        if [ ! -e \"/sys/class/net/lime_br0\" ]; then
            ip link add name lime_br0 type bridge
            ip addr add 10.13.0.2/16 dev lime_br0
            ip link set lime_br0 up
        fi
        
        # Add TAP interface to bridge
        ip link set lime_tap${node_id}_0 master lime_br0
        
        # Prepare rootfs
        temp_dir=/tmp/lime_rootfs_${node_id}
        rm -rf \$temp_dir
        mkdir -p \$temp_dir
        tar xf '$ROOTFS_PATH' -C \$temp_dir
        
        # Copy lime-packages overlay
        for package in './packages/*/files/'*; do
            if [ -e \"\$package\" ]; then
                cp -r \"\$package\" \$temp_dir/
            fi
        done
        
        # Build cpio
        ( cd \$temp_dir && find . | cpio --quiet -o -H newc > /tmp/lime_rootfs_${node_id}.cpio )
        
        # Start QEMU with virtio-net (lime-app compatible)
        qemu-system-x86_64 \
            -m 128 \
            -smp 1,sockets=1,cores=1,threads=1 \
            -no-user-config \
            -enable-kvm \
            -nographic \
            -nodefaults \
            -no-reboot \
            -kernel '$KERNEL_PATH' \
            -initrd /tmp/lime_rootfs_${node_id}.cpio \
            -serial mon:stdio \
            -monitor 'telnet::$TELNET_PORT,server,nowait' \
            -netdev tap,id=hostnet0,ifname=lime_tap${node_id}_0,script=no,downscript=no \
            -device virtio-net-pci,netdev=hostnet0,id=net0,mac=52:00:00:ab:c0:${node_id}
    "
    
    sleep 2
    local qemu_pid=$(pgrep -f "qemu-system-x86_64" | head -1)
    print_status "QEMU started with PID: $qemu_pid in screen session '$screen_name'"
    
    # Wait for bridge to be created
    print_status "Waiting for network bridge..."
    for i in {1..15}; do
        if ip link show "$BRIDGE_IFC" >/dev/null 2>&1; then
            print_status "✓ Bridge $BRIDGE_IFC created"
            break
        fi
        sleep 2
        echo -n "."
    done
    
    # Configure network inside QEMU using image-specific configuration
    print_status "Applying image-specific network configuration..."
    source "$SCRIPT_DIR/$NETWORK_SCRIPT"
    setup_libremesh_network
    
    # Test connectivity with image-specific timing
    print_status "Testing connectivity..."
    local max_wait=$((BOOT_WAIT_TIME * 2))
    for i in $(seq 1 $max_wait); do
        if ping -c 1 -W 1 "$QEMU_IP" >/dev/null 2>&1; then
            print_status "✓ $IMAGE_NAME ready at http://$QEMU_IP"
            print_status "✓ lime-app at http://$QEMU_IP/app"
            print_status "✓ Host bridge: $BRIDGE_IP ($BRIDGE_IFC)"
            print_status "✓ Console: telnet localhost $TELNET_PORT"
            return 0
        fi
        
        if [ $((i % 10)) -eq 0 ]; then
            print_warning "Still waiting for $IMAGE_NAME to boot... ($i/$max_wait)"
        fi
        
        sleep 3
        echo -n "."
    done
    
    echo
    print_warning "$IMAGE_NAME not responding yet"
    print_status "QEMU is running - $IMAGE_NAME may need more time to boot"
    print_status "Check: telnet localhost $TELNET_PORT"
    return 0
}

# Stop QEMU
stop_qemu() {
    print_status "Stopping LibreMesh QEMU..."
    
    # Kill QEMU processes
    local qemu_pids=$(pgrep -f "qemu-system-x86_64" || true)
    if [ -n "$qemu_pids" ]; then
        for pid in $qemu_pids; do
            print_status "Stopping QEMU process $pid"
            sudo kill -TERM "$pid" 2>/dev/null || true
        done
        sleep 3
        
        # Force kill if still running
        qemu_pids=$(pgrep -f "qemu-system-x86_64" || true)
        if [ -n "$qemu_pids" ]; then
            for pid in $qemu_pids; do
                print_warning "Force killing QEMU process $pid"
                sudo kill -KILL "$pid" 2>/dev/null || true
            done
        fi
    fi
    
    # Clean up network interfaces
    if ip link show "$BRIDGE_IFC" >/dev/null 2>&1; then
        print_status "Cleaning up bridge $BRIDGE_IFC"
        sudo ip link delete "$BRIDGE_IFC" 2>/dev/null || true
    fi
    
    # Clean up TAP interfaces
    for ifc in $(ip link show | grep -o 'lime_tap[^:]*' || true); do
        if [ -n "$ifc" ]; then
            print_status "Removing TAP interface $ifc"
            sudo ip link delete "$ifc" 2>/dev/null || true
        fi
    done
    
    print_status "QEMU stopped and interfaces cleaned up"
}

# Show status
show_status() {
    print_status "LibreMesh QEMU Status:"
    
    if check_qemu_running; then
        print_status "✓ QEMU running at $QEMU_IP"
        print_status "✓ Bridge: $BRIDGE_IFC ($BRIDGE_IP)"
        print_status "✓ Console: telnet localhost 4540"
        
        # Test web interface
        if curl -s --connect-timeout 3 "http://$QEMU_IP/" >/dev/null 2>&1; then
            print_status "✓ Web interface accessible"
        else
            print_warning "✗ Web interface not responding"
        fi
        
        # Test lime-app
        if curl -s --connect-timeout 3 "http://$QEMU_IP/app/" >/dev/null 2>&1; then
            print_status "✓ lime-app accessible"
        else
            print_warning "✗ lime-app not found"
        fi
    else
        print_warning "✗ QEMU not running"
        print_status "Start with: lime qemu start"
    fi
}

# Console access
connect_console() {
    # Try to get telnet port from running config, fallback to default
    local console_port="${TELNET_PORT:-4540}"
    
    print_status "Connecting to LibreMesh console on port $console_port..."
    print_status "Use Ctrl+] then 'quit' to exit"
    telnet localhost "$console_port"
}

# Deploy lime-app to QEMU
deploy_lime_app() {
    if [ ! -d "../../repos/lime-app" ]; then
        print_error "lime-app repository not found"
        return 1
    fi
    
    print_status "Deploying lime-app to LibreMesh QEMU..."
    
    cd "../../repos/lime-app"
    
    # Build lime-app
    print_status "Building lime-app..."
    if npm run | grep -q "build:production"; then
        npm run build:production
    else
        npm run build
    fi
    
    # Deploy to lime-packages
    local app_dir="$LIME_PACKAGES_DIR/packages/lime-app/files/www/app"
    mkdir -p "$app_dir"
    rm -rf "$app_dir"/*
    cp -r build/* "$app_dir/"
    
    print_status "lime-app deployed to lime-packages"
    
    # If QEMU is running, try live deployment
    if check_qemu_running; then
        print_status "Attempting live deployment..."
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
            -r build/* root@"$QEMU_IP":/www/app/ 2>/dev/null; then
            print_status "✓ Live deployment successful"
        else
            print_warning "Live deployment failed - restart QEMU to apply changes"
        fi
    fi
    
    print_status "Deployment complete"
}

# Main command handling
case "${1:-help}" in
    start)
        start_qemu
        ;;
    stop)
        stop_qemu
        ;;
    restart)
        stop_qemu
        sleep 2
        start_qemu
        ;;
    status)
        show_status
        ;;
    console)
        connect_console
        ;;
    deploy)
        deploy_lime_app
        ;;
    configs)
        show_available_configs
        ;;
    help|--help|-h)
        echo "LibreMesh QEMU Management"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|console|deploy|help}"
        echo ""
        echo "Commands:"
        echo "  start    - Start LibreMesh QEMU"
        echo "  stop     - Stop LibreMesh QEMU"
        echo "  restart  - Restart LibreMesh QEMU"
        echo "  status   - Show QEMU status"
        echo "  console  - Connect to QEMU console"
        echo "  deploy   - Build and deploy lime-app"
        echo "  configs  - Show available image configurations"
        echo "  help     - Show this help"
        echo ""
        echo "Network:"
        echo "  LibreMesh: http://10.13.0.1"
        echo "  lime-app:  http://10.13.0.1/app"
        echo "  Console:   telnet localhost 4540 (or check status for exact port)"
        echo ""
        echo "Environment Variables:"
        echo "  QEMU_IMAGE_CONFIG - Select image configuration (libremesh-2305|librerouteros-2410)"
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac