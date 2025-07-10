#!/bin/bash
#
# LibreRouterOS Docker Build Wrapper
# 
# This script simplifies building LibreRouterOS using Docker
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
LibreRouterOS Docker Build Wrapper

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    build [target]     Build LibreRouterOS firmware
                      targets: librerouter, x86_64, multi (default: x86_64)
    shell             Open interactive shell in build container
    clean             Clean build artifacts and containers
    logs              Show build logs
    status            Show container status
    stop              Stop running containers
    
Options:
    -f, --force       Force rebuild of Docker image
    -j, --jobs N      Number of parallel build jobs
    -h, --help        Show this help

Examples:
    $0 build x86_64           # Build for x86_64
    $0 build librerouter      # Build for LibreRouter hardware
    $0 shell                  # Open development shell
    $0 clean                  # Clean everything

Environment Variables:
    DOCKER_BUILDKIT=1         Enable Docker BuildKit (recommended)
    MAKEFLAGS=-j4             Set parallel jobs for make

EOF
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running or not accessible"
        print_info "Try: sudo systemctl start docker"
        exit 1
    fi
}

build_image() {
    local force_rebuild="$1"
    
    print_header "Building LibreRouterOS Docker image..."
    
    if [ "$force_rebuild" = "true" ]; then
        print_info "Force rebuilding Docker image..."
        docker-compose build --no-cache librerouteros-builder
    else
        docker-compose build librerouteros-builder
    fi
}

build_firmware() {
    local target="${1:-x86_64}"
    local jobs="${2:-$(nproc)}"
    
    print_header "Building LibreRouterOS firmware for target: $target"
    print_info "Using $jobs parallel jobs"
    
    # Clean any existing build containers
    docker-compose down -v 2>/dev/null || true
    
    # Start build
    docker-compose run --rm \
        -e "MAKEFLAGS=-j$jobs" \
        librerouteros-builder \
        "./build.sh all -t $target"
}

open_shell() {
    print_header "Opening interactive shell in build environment..."
    
    docker-compose run --rm librerouteros-shell
}

clean_all() {
    print_header "Cleaning LibreRouterOS build environment..."
    
    print_info "Stopping containers..."
    docker-compose down -v 2>/dev/null || true
    
    print_info "Removing Docker volumes..."
    docker volume rm librerouteros_librerouteros-dl librerouteros_librerouteros-build 2>/dev/null || true
    
    print_info "Removing Docker images..."
    docker rmi librerouteros_librerouteros-builder 2>/dev/null || true
    
    print_info "Cleaning local build artifacts..."
    rm -rf bin/ build_dir/ staging_dir/ tmp/ logs/ dl/ .config build.log 2>/dev/null || true
    
    print_info "Clean completed"
}

show_logs() {
    print_header "Showing build logs..."
    docker-compose logs -f librerouteros-builder 2>/dev/null || echo "No logs available"
}

show_status() {
    print_header "Container status:"
    docker-compose ps
    
    print_header "Volume status:"
    docker volume ls | grep librerouteros || echo "No volumes found"
    
    print_header "Image status:"
    docker images | grep librerouteros || echo "No images found"
}

stop_containers() {
    print_header "Stopping LibreRouterOS containers..."
    docker-compose down
}

main() {
    local command="${1:-build}"
    local force_rebuild="false"
    local jobs="$(nproc)"
    local target="x86_64"
    
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force_rebuild="true"
                shift
                ;;
            -j|--jobs)
                jobs="$2"
                shift 2
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
                target="$1"
                shift
                ;;
        esac
    done
    
    # Check requirements
    check_requirements
    
    # Enable BuildKit for better performance
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # Execute command
    case "$command" in
        build)
            build_image "$force_rebuild"
            build_firmware "$target" "$jobs"
            ;;
        shell)
            build_image "$force_rebuild"
            open_shell
            ;;
        clean)
            clean_all
            ;;
        logs)
            show_logs
            ;;
        status)
            show_status
            ;;
        stop)
            stop_containers
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

main "$@"