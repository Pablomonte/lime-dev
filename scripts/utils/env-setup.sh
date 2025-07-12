#!/usr/bin/env bash
#
# Environment Setup Script for Lime-Build
# Sets up environment variables and configuration for reproducible builds
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_PARSER="$SCRIPT_DIR/config-parser.sh"

# Source the config parser
if [[ -f "$CONFIG_PARSER" ]]; then
    source "$CONFIG_PARSER"
else
    echo "Error: Config parser not found at $CONFIG_PARSER" >&2
    exit 1
fi

# Set up environment variables from configuration
setup_build_environment() {
    local release_mode="${LIME_RELEASE_MODE:-false}"
    
    echo "Setting up Lime-Build environment..."
    echo "Release mode: $release_mode"
    
    # Export common environment variables
    export LIME_BUILD_DIR="$LIME_BUILD_DIR"
    export LIME_REPOS_DIR="$LIME_BUILD_DIR/repos"
    export LIME_CACHE_DIR="$LIME_BUILD_DIR/cache"
    export LIME_LOGS_DIR="$LIME_BUILD_DIR/logs"
    export LIME_RELEASE_MODE="$release_mode"
    
    # Get versions from config
    export OPENWRT_VERSION=$(get_config_value "firmware_versions" "openwrt_version")
    export LIBREMESH_VERSION=$(get_config_value "firmware_versions" "libremesh_version")
    export LIBREROUTEROS_VERSION=$(get_config_value "firmware_versions" "librerouteros_version")
    
    # Build configuration
    export DEFAULT_TARGET=$(get_config_value "build_targets" "default_target")
    export DEVELOPMENT_TARGET=$(get_config_value "build_targets" "development_target")
    export MULTI_TARGET=$(get_config_value "build_targets" "multi_target")
    
    # System requirements
    export MIN_RAM_GB=$(get_config_value "system_requirements" "min_ram_gb")
    export MIN_DISK_GB=$(get_config_value "system_requirements" "min_disk_gb")
    
    # QEMU configuration
    export QEMU_BRIDGE_INTERFACE=$(get_config_value "qemu_config" "bridge_interface")
    export QEMU_BRIDGE_IP=$(get_config_value "qemu_config" "bridge_ip")
    export QEMU_GUEST_IP=$(get_config_value "qemu_config" "guest_ip")
    export QEMU_WEB_ACCESS=$(get_config_value "qemu_config" "web_access")
    
    # Node.js configuration
    export NODE_MIN_VERSION=$(get_config_value "node_config" "node_min_version")
    export NPM_REGISTRY=$(get_config_value "node_config" "npm_registry")
    
    # Build flags
    export ENABLE_DEBUG=$(get_config_value "build_flags" "enable_debug")
    export ENABLE_CCACHE=$(get_config_value "build_flags" "enable_ccache")
    export PARALLEL_JOBS=$(get_config_value "build_flags" "parallel_jobs")
    export TARGET_ARCH=$(get_config_value "build_flags" "target_arch")
    
    # Create necessary directories
    mkdir -p "$LIME_CACHE_DIR" "$LIME_LOGS_DIR"
    
    echo "Environment setup complete."
}

# Check system requirements
check_system_requirements() {
    local min_ram_gb="$MIN_RAM_GB"
    local min_disk_gb="$MIN_DISK_GB"
    
    echo "Checking system requirements..."
    
    # Check RAM
    local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_ram_gb=$((total_ram_kb / 1024 / 1024))
    
    if [[ $total_ram_gb -lt $min_ram_gb ]]; then
        echo "WARNING: System has ${total_ram_gb}GB RAM, minimum ${min_ram_gb}GB recommended" >&2
    else
        echo "RAM: ${total_ram_gb}GB (OK)"
    fi
    
    # Check disk space
    local available_gb=$(df "$LIME_BUILD_DIR" | tail -1 | awk '{print int($4/1024/1024)}')
    
    if [[ $available_gb -lt $min_disk_gb ]]; then
        echo "WARNING: Available disk space ${available_gb}GB, minimum ${min_disk_gb}GB required" >&2
    else
        echo "Disk space: ${available_gb}GB available (OK)"
    fi
}

# Show current environment
show_environment() {
    echo "Lime-Build Environment:"
    echo "  Build directory: $LIME_BUILD_DIR"
    echo "  Release mode: $LIME_RELEASE_MODE"
    echo "  OpenWrt version: $OPENWRT_VERSION"
    echo "  LibreMesh version: $LIBREMESH_VERSION"
    echo "  LibreRouterOS version: $LIBREROUTEROS_VERSION"
    echo "  Default target: $DEFAULT_TARGET"
    echo "  QEMU guest IP: $QEMU_GUEST_IP"
    echo "  Web access: $QEMU_WEB_ACCESS"
}

# Export repository configurations for scripts
export_repo_configs() {
    local repos=(lime_app lime_packages librerouteros kconfig_utils openwrt)
    
    for repo in "${repos[@]}"; do
        local config=$(get_repo_config "$repo")
        if [[ -n "$config" ]]; then
            IFS='|' read -r url branch remote <<< "$config"
            local dir_name="${repo/_/-}"
            
            # Export repository information
            export "REPO_${repo^^}_URL=$url"
            export "REPO_${repo^^}_BRANCH=$branch"
            export "REPO_${repo^^}_REMOTE=$remote"
            export "REPO_${repo^^}_DIR=$LIME_REPOS_DIR/$dir_name"
        fi
    done
}

# Main function
main() {
    case "${1:-setup}" in
        "setup")
            setup_build_environment
            export_repo_configs
            check_system_requirements
            ;;
        "show"|"info")
            setup_build_environment
            show_environment
            ;;
        "check")
            setup_build_environment
            check_system_requirements
            ;;
        "release")
            LIME_RELEASE_MODE=true
            setup_build_environment
            export_repo_configs
            echo "Environment configured for RELEASE MODE"
            ;;
        "help")
            echo "Environment Setup for Lime-Build"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup     - Set up build environment (default)"
            echo "  show      - Show current environment"
            echo "  check     - Check system requirements"
            echo "  release   - Set up for release mode"
            echo "  help      - Show this help"
            echo ""
            echo "Environment variables:"
            echo "  LIME_RELEASE_MODE - Enable release mode (true/false)"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# If being sourced, just set up the environment
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    setup_build_environment
    export_repo_configs
else
    main "$@"
fi