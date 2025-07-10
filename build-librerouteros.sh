#!/bin/bash
#
# LibreRouterOS Build Orchestrator
# 
# This script orchestrates the complete build process for LibreRouterOS
# using the containerized build environment developed during our session.
#
# Usage: ./build-librerouteros.sh <target_repo_path> <target> [jobs]
#
# Copyright (C) 2025 LibreRouter Contributors
# License: GNU GPL v3 or later

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="${1}"
BUILD_TARGET="${2:-x86_64}"
BUILD_JOBS="${3:-$(nproc)}"

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

print_header() {
    echo -e "${BLUE}[LIME-BUILD]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
LibreRouterOS Build Orchestrator

Usage: $0 <target_repo_path> <target> [jobs]

Arguments:
    target_repo_path    Path to LibreRouterOS repository
    target              Build target (librerouter, x86_64, multi)
    jobs                Number of parallel jobs (default: $(nproc))

Examples:
    $0 ../librerouteros x86_64          # Build x86_64 with default jobs
    $0 ../librerouteros librerouter 8   # Build LibreRouter v1 with 8 jobs
    $0 ../librerouteros multi 4         # Build multi-device with 4 jobs

Environment Variables:
    BUILD_JOBS          Override job count
    BUILD_LOG_LEVEL     Set to 'verbose' for detailed output
    DOWNLOAD_DIR        Custom download directory

EOF
}

# Function to validate arguments
validate_args() {
    if [ -z "$TARGET_REPO" ]; then
        print_error "Target repository path required"
        usage
        exit 1
    fi
    
    if [ ! -d "$TARGET_REPO" ]; then
        print_error "Target repository not found: $TARGET_REPO"
        exit 1
    fi
    
    if [ ! -f "$TARGET_REPO/Makefile" ]; then
        print_error "Not a valid OpenWrt repository: $TARGET_REPO"
        exit 1
    fi
    
    case "$BUILD_TARGET" in
        librerouter|x86_64|multi)
            ;;
        *)
            print_error "Unknown build target: $BUILD_TARGET"
            print_info "Valid targets: librerouter, x86_64, multi"
            exit 1
            ;;
    esac
}

# Function to prepare build environment
prepare_environment() {
    print_header "Preparing build environment"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check Docker permissions
    if ! docker info &> /dev/null; then
        print_error "Docker permission denied. Please add user to docker group or use sudo."
        exit 1
    fi
    
    # Resolve absolute path
    TARGET_REPO=$(cd "$TARGET_REPO" && pwd)
    print_info "Target repository: $TARGET_REPO"
    print_info "Build target: $BUILD_TARGET"
    print_info "Build jobs: $BUILD_JOBS"
}

# Function to setup target repository
setup_target_repo() {
    print_header "Setting up target repository"
    
    cd "$TARGET_REPO"
    
    # Check if OpenWrt scripts are missing
    if [ ! -f "scripts/feeds" ] || [ ! -f "scripts/package-metadata.pl" ]; then
        print_info "OpenWrt scripts missing, checking for openwrt repository..."
        
        # Look for openwrt repository in parent directories
        OPENWRT_REPO=""
        for dir in ../openwrt ../../openwrt ../../../openwrt; do
            if [ -d "$dir/scripts" ] && [ -f "$dir/scripts/feeds" ]; then
                OPENWRT_REPO=$(cd "$dir" && pwd)
                break
            fi
        done
        
        if [ -n "$OPENWRT_REPO" ]; then
            print_info "Found OpenWrt repository: $OPENWRT_REPO"
            print_info "Copying missing scripts..."
            cp -r "$OPENWRT_REPO/scripts"/* scripts/
        else
            print_warn "OpenWrt scripts not found. Build may fail."
            print_info "Please ensure OpenWrt repository with scripts is available."
        fi
    fi
    
    # Copy build script to target repository
    cp "$SCRIPT_DIR/build.sh" .
    chmod +x build.sh
    
    print_info "Repository setup complete"
}

# Function to start build process
start_build() {
    print_header "Starting build process"
    
    cd "$SCRIPT_DIR"
    
    # Check if Docker build script exists
    if [ ! -f "docker-build-clean.sh" ]; then
        print_error "Docker build script not found: docker-build-clean.sh"
        exit 1
    fi
    
    # Copy Dockerfile to target repository for Docker context
    cp Dockerfile.librerouteros-v2 "$TARGET_REPO/"
    
    # Start build from target repository
    cd "$TARGET_REPO"
    
    # Run Docker build
    print_info "Starting Docker build..."
    BUILD_LOG="$TARGET_REPO/lime-build.log"
    
    if [ "${BUILD_LOG_LEVEL:-}" = "verbose" ]; then
        "$SCRIPT_DIR/docker-build-clean.sh" "$BUILD_TARGET" "$BUILD_JOBS" 2>&1 | tee "$BUILD_LOG"
    else
        "$SCRIPT_DIR/docker-build-clean.sh" "$BUILD_TARGET" "$BUILD_JOBS" > "$BUILD_LOG" 2>&1 &
        BUILD_PID=$!
        
        print_info "Build started in background (PID: $BUILD_PID)"
        print_info "Log file: $BUILD_LOG"
        print_info "Monitor with: $SCRIPT_DIR/monitor-build.sh start"
        
        # Wait for build to complete
        if wait $BUILD_PID; then
            print_info "Build completed successfully!"
        else
            print_error "Build failed. Check log: $BUILD_LOG"
            exit 1
        fi
    fi
}

# Function to show build results
show_results() {
    print_header "Build Results"
    
    cd "$TARGET_REPO"
    
    # Check for firmware images
    if [ -d "bin/targets" ]; then
        print_info "Firmware images generated:"
        find bin/targets -name "*.bin" -o -name "*.img.gz" 2>/dev/null | while read -r image; do
            SIZE=$(du -h "$image" | cut -f1)
            echo "  - $image ($SIZE)"
        done
    else
        print_warn "No firmware images found in bin/targets"
    fi
    
    # Show build statistics
    if [ -f "lime-build.log" ]; then
        BUILD_TIME=$(grep -o "Build completed" lime-build.log | wc -l)
        if [ "$BUILD_TIME" -gt 0 ]; then
            print_info "Build completed successfully"
        fi
    fi
}

# Main execution
main() {
    print_header "LibreRouterOS Build Orchestrator"
    
    # Handle help
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
    fi
    
    # Validate arguments
    validate_args
    
    # Prepare environment
    prepare_environment
    
    # Setup target repository
    setup_target_repo
    
    # Start build process
    start_build
    
    # Show results
    show_results
    
    print_header "Build orchestration complete"
}

# Run main function
main "$@"