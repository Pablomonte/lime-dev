#!/usr/bin/env bash
#
# QEMU Image Configuration System
# Supports multiple image sets with specific network and boot configurations
# Migrated from lime-app to lime-dev
#

# Configuration for LibreMesh 23.05 (Stable)
config_libremesh_2305() {
    IMAGE_TYPE="libremesh-2305"
    IMAGE_NAME="LibreMesh 23.05.5 (Stable)"
    
    # Image paths (adjusted for lime-dev structure) - using tar.gz format for qemu_dev_start compatibility
    ROOTFS_PATH="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-rootfs.tar.gz"
    KERNEL_PATH="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-generic-initramfs-kernel.bin"
    
    # Network configuration
    QEMU_IP="10.13.0.1"
    BRIDGE_IP="10.13.0.2/16"
    TELNET_PORT="45400"
    
    # Boot timing
    BOOT_WAIT_TIME=15
    NETWORK_SETUP_DELAY=2
    
    # Network interface preferences (in order)
    PREFERRED_INTERFACES=("br-lan" "eth0")
    
    # Services configuration
    ENABLE_UHTTPD=true
    ENABLE_UBUS=true
    DEFAULT_PASSWORD="admin"
    
    # LibreMesh specific settings
    MESH_NETWORK=true
    AUTO_CONFIGURE_BATMAN=true
    
    # Network configuration script
    NETWORK_SCRIPT="qemu-network-libremesh.sh"
    
    print_status "Using LibreMesh 23.05.5 configuration (Known stable)"
}

# Configuration for LibreRouterOS 24.10 (Development)
config_librerouteros_2410() {
    IMAGE_TYPE="librerouteros-2410"
    IMAGE_NAME="LibreRouterOS 24.10.1 (Development)"
    
    # Image paths (adjusted for lime-dev structure)
    ROOTFS_PATH="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-rootfs.tar.gz"
    KERNEL_PATH="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-generic-kernel.bin"
    
    # Network configuration
    QEMU_IP="10.13.0.1"
    BRIDGE_IP="10.13.0.2/16"
    TELNET_PORT="45401"  # Different port to avoid conflicts
    
    # Boot timing (LibreRouterOS needs more time)
    BOOT_WAIT_TIME=20
    NETWORK_SETUP_DELAY=3
    
    # Network interface preferences (LibreRouterOS specific)
    PREFERRED_INTERFACES=("eth0" "br-lan" "lan")
    
    # Services configuration
    ENABLE_UHTTPD=true
    ENABLE_UBUS=true
    DEFAULT_PASSWORD="admin"
    
    # LibreRouterOS specific settings
    MESH_NETWORK=false
    AUTO_CONFIGURE_BATMAN=false
    REQUIRES_MANUAL_NETWORK_SETUP=true
    
    # Network configuration script
    NETWORK_SCRIPT="qemu-network-librerouteros.sh"
    
    print_status "Using LibreRouterOS 24.10.1 configuration (Fresh build for development)"
}

# Auto-detect available images and select best configuration
auto_detect_image_config() {
    print_status "Auto-detecting available images..."
    
    local libremesh_rootfs="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-rootfs.tar.gz"
    local libremesh_kernel="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-generic-initramfs-kernel.bin"
    
    local librerouteros_rootfs="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-rootfs.tar.gz"
    local librerouteros_kernel="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-generic-kernel.bin"
    
    # Check LibreMesh 23.05 (Stable - preferred for compatibility)
    if [ -f "$libremesh_rootfs" ] && [ -f "$libremesh_kernel" ]; then
        print_status "✓ LibreMesh 23.05.5 images found (stable)"
        AVAILABLE_CONFIGS+=("libremesh-2305")
    fi
    
    # Check LibreRouterOS 24.10 (Development)
    if [ -f "$librerouteros_rootfs" ] && [ -f "$librerouteros_kernel" ]; then
        print_status "✓ LibreRouterOS 24.10.1 images found (development)"
        AVAILABLE_CONFIGS+=("librerouteros-2410")
    fi
    
    if [ ${#AVAILABLE_CONFIGS[@]} -eq 0 ]; then
        print_error "No compatible images found in $LIME_PACKAGES_DIR/build/"
        print_error "Available files:"
        ls -la "$LIME_PACKAGES_DIR/build/" | grep -E "\.(img\.gz|tar\.gz|bin|bzImage)$" || echo "  No image files found"
        exit 1
    fi
    
    # Default selection logic
    if [ -z "$QEMU_IMAGE_CONFIG" ]; then
        if [[ " ${AVAILABLE_CONFIGS[@]} " =~ " libremesh-2305 " ]]; then
            QEMU_IMAGE_CONFIG="libremesh-2305"
            print_status "Auto-selected LibreMesh 23.05.5 (stable default)"
        else
            QEMU_IMAGE_CONFIG="librerouteros-2410"
            print_status "Auto-selected LibreRouterOS 24.10.1 (only available option)"
        fi
    fi
    
    # Load the selected configuration
    case "$QEMU_IMAGE_CONFIG" in
        "libremesh-2305")
            config_libremesh_2305
            ;;
        "librerouteros-2410")
            config_librerouteros_2410
            ;;
        *)
            print_error "Unknown image configuration: $QEMU_IMAGE_CONFIG"
            print_error "Available configs: ${AVAILABLE_CONFIGS[*]}"
            exit 1
            ;;
    esac
}

# Validate selected configuration
validate_image_config() {
    print_status "Validating $IMAGE_NAME configuration..."
    
    if [ ! -f "$ROOTFS_PATH" ]; then
        print_error "Rootfs not found: $ROOTFS_PATH"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_PATH" ]; then
        print_error "Kernel not found: $KERNEL_PATH"
        exit 1
    fi
    
    # Validate rootfs format based on image type
    if [[ "$IMAGE_TYPE" == "librerouteros-2410" ]] || [[ "$IMAGE_TYPE" == "libremesh-2305" ]]; then
        if ! tar -tf "$ROOTFS_PATH" >/dev/null 2>&1; then
            print_error "$IMAGE_NAME rootfs must be extractable tar.gz format"
            print_error "Current file: $ROOTFS_PATH"
            print_error "Download the correct format from:"
            print_error "  LibreMesh: https://downloads.libremesh.org/releases/2024.1-ow23.05.5/targets/x86/64/default/libremesh-2024.1-ow23.05.5-default-x86-64-rootfs.tar.gz"
            exit 1
        fi
    fi
    
    print_status "✓ Configuration validated: $IMAGE_NAME"
    print_status "  Rootfs: $(basename "$ROOTFS_PATH")"
    print_status "  Kernel: $(basename "$KERNEL_PATH")"
    print_status "  Network: $QEMU_IP (bridge: $BRIDGE_IP)"
    print_status "  Telnet: $TELNET_PORT"
}

# Show available configurations
show_available_configs() {
    echo "Available QEMU Image Configurations:"
    echo ""
    
    local libremesh_rootfs="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-rootfs.tar.gz"
    local libremesh_kernel="$LIME_PACKAGES_DIR/build/libremesh-2024.1-ow23.05.5-default-x86-64-generic-initramfs-kernel.bin"
    
    if [ -f "$libremesh_rootfs" ] && [ -f "$libremesh_kernel" ]; then
        echo "  libremesh-2305    LibreMesh 23.05.5 (Stable, Default)"
        echo "                    - Known working configuration"
        echo "                    - Mesh networking enabled"
        echo "                    - Port 45400"
    fi
    
    local librerouteros_rootfs="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-rootfs.tar.gz"
    local librerouteros_kernel="$LIME_PACKAGES_DIR/build/librerouteros-24.10.1-r28597-0425664679-x86-64-generic-kernel.bin"
    
    if [ -f "$librerouteros_rootfs" ] && [ -f "$librerouteros_kernel" ]; then
        echo "  librerouteros-2410 LibreRouterOS 24.10.1 (Development)"
        echo "                    - Fresh build with latest features"
        echo "                    - Manual network configuration"
        echo "                    - Port 45401"
    fi
    
    echo ""
    echo "Usage (lime-dev):"
    echo "  ./tools/qemu/qemu-manager.sh start                          # Auto-detect (prefers stable)"
    echo "  QEMU_IMAGE_CONFIG=libremesh-2305 ./tools/qemu/qemu-manager.sh start"
    echo "  QEMU_IMAGE_CONFIG=librerouteros-2410 ./tools/qemu/qemu-manager.sh start"
}

# Initialize configuration arrays
AVAILABLE_CONFIGS=()