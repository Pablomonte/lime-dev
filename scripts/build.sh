#!/bin/bash
#
# LibreRouterOS Build Script
# 
# This script formalizes the build process for LibreRouterOS,
# providing consistency and automation while maintaining compatibility
# with the traditional OpenWrt build system.
#
# Copyright (C) 2025 LibreRouter Contributors
# License: GNU GPL v3 or later

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-${BUILD_DIR}/dl}"
BUILD_LOG="${BUILD_DIR}/build.log"
NUM_CORES=$(nproc)

# Default build target
BUILD_TARGET="${BUILD_TARGET:-librerouter}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking build prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git gcc g++ make patch perl python3 unzip rsync wget; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies and try again"
        exit 1
    fi
    
    print_info "All prerequisites satisfied"
}

# Function to update feeds
update_feeds() {
    print_info "Updating package feeds..."
    
    # Check if feeds script exists, create if not
    if [ ! -f "./scripts/feeds" ]; then
        print_info "Creating feeds script..."
        make scripts/feeds
    fi
    
    ./scripts/feeds update -a || {
        print_error "Failed to update feeds"
        exit 1
    }
    
    print_info "Installing packages from feeds..."
    ./scripts/feeds install -a || {
        print_error "Failed to install packages"
        exit 1
    }
}

# Function to configure build
configure_build() {
    local config_file=""
    
    case "$BUILD_TARGET" in
        librerouter|librerouter-v1)
            config_file="configs/default_config"
            print_info "Configuring for LibreRouter v1"
            ;;
        multi)
            config_file="configs/default_config_multi"
            print_info "Configuring for multiple ath79 devices"
            ;;
        x86_64)
            config_file="configs/default_config_x86_64"
            print_info "Configuring for x86_64 testing"
            ;;
        *)
            print_error "Unknown build target: $BUILD_TARGET"
            print_info "Valid targets: librerouter, multi, x86_64"
            exit 1
            ;;
    esac
    
    if [ -f "$config_file" ]; then
        cp "$config_file" .config
        print_info "Configuration loaded from $config_file"
    else
        print_error "Configuration file not found: $config_file"
        exit 1
    fi
    
    # Generate full config with force flag
    FORCE=1 make defconfig
}

# Function to apply custom configurations
apply_custom_config() {
    print_info "Applying custom configurations..."
    
    # Ensure essential packages are selected
    ./scripts/kconfig.pl .config \
        CONFIG_PACKAGE_lime-full=y \
        CONFIG_PACKAGE_librerouter-hw=y \
        CONFIG_PACKAGE_deferrable-reboot=y \
        CONFIG_PACKAGE_check-date-http=y \
        CONFIG_PACKAGE_eupgrade=y \
        CONFIG_BUILD_LOG=y || {
        print_warn "Some configurations could not be applied"
    }
}

# Function to build firmware
build_firmware() {
    print_info "Starting build process..."
    print_info "Using $NUM_CORES CPU cores"
    print_info "Build output will be logged to: $BUILD_LOG"
    
    # Create download directory if needed
    mkdir -p "$DOWNLOAD_DIR"
    
    # Start build with logging and force flag
    if FORCE=1 make -j"$NUM_CORES" V=s 2>&1 | tee "$BUILD_LOG"; then
        print_info "Build completed successfully!"
        
        # Show build artifacts
        print_info "Firmware images created:"
        find bin/targets -name "*.bin" -o -name "*.img.gz" 2>/dev/null | while read -r image; do
            echo "  - $image"
        done
    else
        print_error "Build failed! Check $BUILD_LOG for details"
        exit 1
    fi
}

# Function to clean build environment
clean_build() {
    print_info "Cleaning build environment..."
    
    case "$1" in
        clean)
            make clean
            print_info "Build artifacts cleaned"
            ;;
        dirclean)
            make dirclean
            print_info "Complete clean including toolchain"
            ;;
        distclean)
            make distclean
            rm -rf bin/ build_dir/ staging_dir/ toolchain/ tmp/ logs/
            print_info "Distribution clean completed"
            ;;
        *)
            print_error "Unknown clean option: $1"
            exit 1
            ;;
    esac
}

# Function to show usage
usage() {
    cat << EOF
LibreRouterOS Build Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    all          Run complete build process (default)
    prereq       Check build prerequisites only
    feeds        Update and install package feeds
    config       Configure build for target
    build        Build firmware images
    clean        Clean build artifacts
    dirclean     Deep clean including toolchain
    distclean    Complete clean of build environment
    menuconfig   Interactive configuration menu

Options:
    -t, --target TARGET    Build target (librerouter, multi, x86_64)
    -j, --jobs NUM        Number of parallel jobs (default: $(nproc))
    -d, --dl-dir DIR      Download directory (default: ./dl)
    -h, --help           Show this help message

Environment Variables:
    BUILD_TARGET    Default build target
    DOWNLOAD_DIR    Custom download directory
    NUM_CORES       Number of CPU cores to use

Examples:
    $0                    # Full build for LibreRouter
    $0 -t x86_64          # Build for x86_64 testing
    $0 clean              # Clean build artifacts
    $0 menuconfig         # Interactive configuration

EOF
}

# Main script logic
main() {
    local command="${1:-all}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)
                BUILD_TARGET="$2"
                shift 2
                ;;
            -j|--jobs)
                NUM_CORES="$2"
                shift 2
                ;;
            -d|--dl-dir)
                DOWNLOAD_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        all)
            check_prerequisites
            update_feeds
            configure_build
            apply_custom_config
            build_firmware
            ;;
        prereq)
            check_prerequisites
            ;;
        feeds)
            update_feeds
            ;;
        config)
            configure_build
            apply_custom_config
            ;;
        build)
            build_firmware
            ;;
        clean|dirclean|distclean)
            clean_build "$command"
            ;;
        menuconfig)
            make menuconfig
            ;;
        help)
            usage
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"