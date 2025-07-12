#!/bin/bash
#
# LibreRouterOS Docker Build - Native Integration
# 
# This script uses the original LibreRouterOS Docker system directly
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
LIBREROUTEROS_DIR="$LIME_BUILD_DIR/repos/librerouteros"

# Check if librerouteros repository exists
if [[ ! -d "$LIBREROUTEROS_DIR" ]]; then
    echo "LibreRouterOS repository not found at: $LIBREROUTEROS_DIR"
    echo "Run setup-lime-dev.sh first to clone repositories"
    exit 1
fi

cd "$LIBREROUTEROS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}[DOCKER]${NC} $1"
}

usage() {
    cat << EOF
LibreRouterOS Docker Build - Native Integration

Usage: $0 [TARGET] [OPTIONS]

Targets:
    librerouter-v1        LibreRouter v1 hardware (default)
    hilink_hlk-7621a-evb  HiLink HLK-7621A evaluation board
    x86_64                x86_64 for testing (if supported)
    
Options:
    --shell              Open interactive shell in build container
    --clean              Clean Docker build cache
    --download-only      Only download dependencies
    -h, --help           Show this help

Examples:
    $0 librerouter-v1         # Build LibreRouter v1 firmware
    $0 hilink_hlk-7621a-evb   # Build for HiLink board
    $0 --shell                # Open development shell
    $0 --clean                # Clean Docker environment

Note: This script uses the original LibreRouterOS Docker build system
with the final-release lime-packages configuration.

EOF
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running or not accessible"
        print_info "Try: sudo systemctl start docker"
        exit 1
    fi
    
    # Check if librerouteros_build.sh exists
    if [[ ! -f "./librerouteros_build.sh" ]]; then
        print_error "librerouteros_build.sh not found in current directory"
        print_error "Current directory: $(pwd)"
        exit 1
    fi
}

build_docker_image() {
    print_header "Building LibreRouterOS Docker image..."
    
    # Use the original Dockerfile.build from LibreRouterOS
    docker build -f Dockerfiles/Dockerfile.build -t librerouteros:build .
}

build_firmware() {
    local target="${1:-librerouter-v1}"
    
    print_header "Building LibreRouterOS firmware for target: $target"
    print_info "Using original librerouteros_build.sh with Docker"
    
    # Build the Docker image first
    build_docker_image
    
    # Run the native LibreRouterOS build in Docker
    docker run --rm -it \
        -v "$(pwd):/workspace" \
        -w /workspace \
        librerouteros:build \
        bash -c "./librerouteros_build.sh $target"
}

download_only() {
    local target="${1:-librerouter-v1}"
    
    print_header "Downloading dependencies for target: $target"
    
    build_docker_image
    
    docker run --rm -it \
        -v "$(pwd):/workspace" \
        -w /workspace \
        -e BUILD_DOWNLOAD_ONLY=true \
        librerouteros:build \
        bash -c "./librerouteros_build.sh $target"
}

open_shell() {
    print_header "Opening interactive shell in LibreRouterOS build environment..."
    
    build_docker_image
    
    docker run --rm -it \
        -v "$(pwd):/workspace" \
        -w /workspace \
        librerouteros:build \
        bash
}

clean_docker() {
    print_header "Cleaning LibreRouterOS Docker environment..."
    
    print_info "Removing Docker image..."
    docker rmi librerouteros:build 2>/dev/null || print_info "Image not found"
    
    print_info "Pruning Docker build cache..."
    docker builder prune -f
    
    print_info "Docker clean completed"
}

main() {
    local target=""
    local command="build"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --shell)
                command="shell"
                shift
                ;;
            --clean)
                command="clean"
                shift
                ;;
            --download-only)
                command="download"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$target" ]]; then
                    target="$1"
                else
                    print_error "Multiple targets specified: $target and $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Set default target if none specified
    target="${target:-librerouter-v1}"
    
    # Check requirements
    check_requirements
    
    # Enable BuildKit for better performance
    export DOCKER_BUILDKIT=1
    
    print_info "LibreRouterOS Docker Build - Native Integration"
    print_info "Target: $target"
    print_info "Command: $command"
    print_info "Working directory: $(pwd)"
    
    # Execute command
    case "$command" in
        build)
            build_firmware "$target"
            ;;
        download)
            download_only "$target"
            ;;
        shell)
            open_shell
            ;;
        clean)
            clean_docker
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"