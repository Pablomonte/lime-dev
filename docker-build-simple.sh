#!/bin/bash
#
# Simple LibreRouterOS Docker Build Script
# Builds everything inside the container to avoid GLIBC issues
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[DOCKER]${NC} $1"
}

TARGET="${1:-x86_64}"
JOBS="${2:-$(nproc)}"

print_header "Building LibreRouterOS in Docker container"
print_info "Target: $TARGET"
print_info "Jobs: $JOBS"

# Build the Docker image
print_info "Building Docker image..."
docker build -t librerouteros-build -f Dockerfile.librerouteros .

# Run the build inside container
print_info "Starting build process..."
docker run --rm \
    -e "MAKEFLAGS=-j$JOBS" \
    -e "FORCE=1" \
    -v "$(pwd)/bin:/workspace/output" \
    librerouteros-build \
    "./build.sh all -t $TARGET"

print_info "Build completed! Check ./bin/ directory for firmware images."