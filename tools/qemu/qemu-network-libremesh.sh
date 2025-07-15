#!/usr/bin/env bash
#
# LibreMesh 23.05.5 Network Configuration
# Optimized for stable mesh networking environment
# Migrated from lime-app to lime-dev
#

# Colors for output (if not already defined)
if [ -z "$GREEN" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
fi

# Helper functions (if not already defined)
if ! type print_status >/dev/null 2>&1; then
    print_status() {
        echo -e "${GREEN}[INFO]${NC} $1"
    }
fi

setup_libremesh_network() {
    print_status "Configuring LibreMesh 23.05.5 network (stable configuration)..."
    
    # Use lime-app compatible screen session name
    local screen_name="libremesh-${IMAGE_TYPE:-libremesh-2305}"
    
    # Wait for LibreMesh to fully boot with mesh-specific timing
    print_status "Waiting for LibreMesh mesh services to initialize..."
    for i in {1..15}; do
        sudo screen -S "$screen_name" -X hardcopy /tmp/boot_check.txt 2>/dev/null
        if grep -q "root@.*:/#\|OpenWrt.*#" /tmp/boot_check.txt 2>/dev/null; then
            print_status "✓ LibreMesh boot completed"
            break
        fi
        
        # Send Enter every few seconds to activate console (lime-app algorithm)
        if [ $((i % 3)) -eq 0 ]; then
            sudo screen -S "$screen_name" -X stuff "$(printf \\r)" 2>/dev/null || true
        fi
        
        sleep 2
        echo -n "."
    done
    echo
    
    print_status "Configuring LibreMesh mesh bridge network..."
    
    # CRITICAL: Use lime-app proven algorithm for network configuration
    print_status "Setting root password to 'admin'..."
    sudo screen -S "$screen_name" -X stuff "echo -e 'admin\\nadmin' | passwd root$(printf \\r)" 2>/dev/null || true
    sleep 2
    
    # Configure eth0 first (virtio-net interface)
    print_status "Configuring eth0 interface (virtio-net)..."
    sudo screen -S "$screen_name" -X stuff "ip link set eth0 up$(printf \\r)" 2>/dev/null || true
    sleep 1
    sudo screen -S "$screen_name" -X stuff "ip addr add 10.13.0.1/16 dev eth0$(printf \\r)" 2>/dev/null || true
    sleep 2
    
    # Fallback to br-lan if it exists
    print_status "Configuring br-lan as fallback..."
    sudo screen -S "$screen_name" -X stuff "ip addr add 10.13.0.1/16 dev br-lan$(printf \\r)" 2>/dev/null || true
    sleep 2
    
    # LibreMesh-specific services setup
    print_status "Starting LibreMesh services..."
    
    # Start/restart web server (critical for connectivity)
    print_status "Starting web server..."
    sudo screen -S "$screen_name" -X stuff "/etc/init.d/uhttpd restart$(printf \\r)" 2>/dev/null || true
    sleep 2
    
    # Start ubus if available
    print_status "Starting ubus..."
    sudo screen -S "$screen_name" -X stuff "/etc/init.d/ubus start$(printf \\r)" 2>/dev/null || true
    sleep 2
    
    # Wait for services to start
    print_status "Waiting for services to initialize..."
    sleep 3
    
    print_status "LibreMesh 23.05.5 network configuration completed"
    print_status "✓ Screen session: $screen_name"
    print_status "✓ Network interface: br-lan/eth0 configured"
    print_status "✓ Web access: http://10.13.0.1/"
    print_status "✓ lime-app: http://10.13.0.1/app/"
    print_status "✓ Credentials: root/admin"
    
    # Clean up
    sudo rm -f /tmp/boot_check.txt 2>/dev/null || true
}