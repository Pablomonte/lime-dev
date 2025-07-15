#!/usr/bin/env bash
#
# QEMU Development Fix Script
# Creates missing TAP interfaces that qemu_dev_start expects but doesn't create
# Migrated from lime-app to lime-dev
#

print_status() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Create missing TAP interfaces for QEMU
fix_qemu_interfaces() {
    local node_id="${1:-00}"
    
    print_status "Creating missing QEMU TAP interfaces for node $node_id..."
    
    # QEMU expects these interfaces but qemu_dev_start only creates lime_tap00_0
    local wan_ifc="lime_tap${node_id}_1"
    local eth2_ifc="lime_tap${node_id}_2"
    
    # Create WAN interface if it doesn't exist
    if [ ! -e "/sys/class/net/$wan_ifc" ]; then
        print_status "Creating $wan_ifc interface..."
        sudo ip tuntap add name "$wan_ifc" mode tap
        sudo ip link set "$wan_ifc" up
        print_status "✓ $wan_ifc created and brought up"
    else
        print_status "✓ $wan_ifc already exists"
    fi
    
    # Create ETH2 interface if it doesn't exist
    if [ ! -e "/sys/class/net/$eth2_ifc" ]; then
        print_status "Creating $eth2_ifc interface..."
        sudo ip tuntap add name "$eth2_ifc" mode tap
        sudo ip link set "$eth2_ifc" up
        print_status "✓ $eth2_ifc created and brought up"
    else
        print_status "✓ $eth2_ifc already exists"
    fi
    
    print_status "All required TAP interfaces are available"
}

# Clean up all TAP interfaces
cleanup_qemu_interfaces() {
    local node_id="${1:-00}"
    
    print_status "Cleaning up QEMU TAP interfaces for node $node_id..."
    
    local interfaces=("lime_tap${node_id}_0" "lime_tap${node_id}_1" "lime_tap${node_id}_2" "lime_br0")
    
    for ifc in "${interfaces[@]}"; do
        if ip link show "$ifc" >/dev/null 2>&1; then
            print_status "Removing interface $ifc"
            sudo ip link delete "$ifc" 2>/dev/null || true
        fi
    done
    
    print_status "TAP interface cleanup completed"
}

# Main command handling
case "${1:-fix}" in
    fix)
        fix_qemu_interfaces "${2:-00}"
        ;;
    cleanup)
        cleanup_qemu_interfaces "${2:-00}"
        ;;
    help|--help|-h)
        echo "Usage: $0 {fix|cleanup} [node_id]"
        echo ""
        echo "Commands:"
        echo "  fix     - Create missing TAP interfaces for QEMU (default)"
        echo "  cleanup - Remove all QEMU TAP interfaces"
        echo ""
        echo "Parameters:"
        echo "  node_id - Node ID (00-99, default: 00)"
        echo ""
        echo "Examples:"
        echo "  $0 fix     # Create missing interfaces for node 00"
        echo "  $0 cleanup # Clean up all interfaces for node 00"
        ;;
    *)
        print_error "Unknown command: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac