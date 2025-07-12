#!/bin/bash
#
# Clean LibreRouterOS Docker Build
# Forces compilation of all tools inside container to avoid GLIBC issues
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

TARGET="${1:-x86_64}"
JOBS="${2:-$(nproc)}"

print_header "Clean LibreRouterOS build in Docker"
print_info "Target: $TARGET"
print_info "Jobs: $JOBS"

# Clean any existing problematic binaries on host
print_info "Cleaning host-compiled binaries..."
find scripts/ -type f -executable -delete 2>/dev/null || true
rm -rf staging_dir/ build_dir/ bin/ tmp/ .config 2>/dev/null || true

# Build the Docker image with v2 approach
print_info "Building clean Docker image..."
docker build -t librerouteros-clean -f Dockerfile.librerouteros-v2 .

# Run the build with tool recompilation
print_info "Starting clean build process..."
docker run --rm \
    -e "MAKEFLAGS=-j$JOBS" \
    -e "FORCE=1" \
    -v "$(pwd)/bin:/workspace/output" \
    librerouteros-clean \
    "./build.sh all -t $TARGET"

if [ $? -eq 0 ]; then
    print_info "Build completed! Check ./bin/ directory for firmware images."
else
    print_error "Build failed. Check logs for details."
    exit 1
fi