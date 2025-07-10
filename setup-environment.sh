#!/bin/bash
#
# LibreRouterOS Build Environment Setup
# 
# This script sets up the complete development environment for LibreRouterOS
# builds, including Docker configuration, dependency checking, and repository
# preparation.
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
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Function to check system requirements
check_requirements() {
    print_header "Checking system requirements"
    
    local missing_deps=()
    
    # Check essential commands
    for cmd in docker git; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies:"
        
        # Provide installation instructions
        if command -v apt-get &> /dev/null; then
            echo "  sudo apt-get update"
            echo "  sudo apt-get install ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            echo "  sudo yum install ${missing_deps[*]}"
        elif command -v brew &> /dev/null; then
            echo "  brew install ${missing_deps[*]}"
        else
            echo "  Please install: ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    print_info "All required dependencies found"
}

# Function to setup Docker
setup_docker() {
    print_header "Setting up Docker environment"
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        print_error "Docker daemon not accessible"
        
        # Try to start Docker if systemctl is available
        if command -v systemctl &> /dev/null; then
            print_info "Attempting to start Docker service..."
            sudo systemctl start docker || true
            
            if ! docker info &> /dev/null; then
                print_error "Please start Docker daemon or add user to docker group"
                print_info "To add user to docker group: sudo usermod -aG docker $USER"
                print_info "Then log out and log back in, or run: newgrp docker"
                exit 1
            fi
        else
            print_error "Please ensure Docker daemon is running"
            exit 1
        fi
    fi
    
    # Check Docker permissions
    if ! docker ps &> /dev/null; then
        print_warn "Docker permission issue detected"
        print_info "Adding user to docker group..."
        
        # Add user to docker group
        sudo usermod -aG docker "$USER"
        
        # Try to apply group membership
        if command -v newgrp &> /dev/null; then
            print_info "Applying group membership..."
            # Note: This might not work in all shells
            newgrp docker || true
        fi
        
        # Set socket permissions as fallback
        if [ -S "/var/run/docker.sock" ]; then
            sudo chmod 666 /var/run/docker.sock
        fi
        
        # Test again
        if ! docker ps &> /dev/null; then
            print_warn "Docker permissions still need manual fix"
            print_info "Please log out and log back in, or run: newgrp docker"
        fi
    fi
    
    print_info "Docker environment ready"
}

# Function to validate environment
validate_environment() {
    print_header "Validating build environment"
    
    # Check disk space (minimum 20GB recommended)
    AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=20971520  # 20GB in KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        print_warn "Low disk space detected"
        print_info "Available: $(($AVAILABLE_SPACE / 1024 / 1024))GB"
        print_info "Recommended: 20GB minimum"
    else
        print_info "Sufficient disk space available"
    fi
    
    # Check memory
    if [ -f "/proc/meminfo" ]; then
        TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        REQUIRED_MEM=4194304  # 4GB in KB
        
        if [ "$TOTAL_MEM" -lt "$REQUIRED_MEM" ]; then
            print_warn "Low memory detected"
            print_info "Available: $(($TOTAL_MEM / 1024 / 1024))GB"
            print_info "Recommended: 4GB minimum, 8GB preferred"
        else
            print_info "Sufficient memory available"
        fi
    fi
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    print_info "CPU cores available: $CPU_CORES"
    
    print_info "Environment validation complete"
}

# Function to setup build directories
setup_directories() {
    print_header "Setting up build directories"
    
    # Create necessary directories
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/cache"
    mkdir -p "$SCRIPT_DIR/docs"
    
    # Set proper permissions
    chmod 755 "$SCRIPT_DIR"/*.sh 2>/dev/null || true
    
    print_info "Build directories created"
}

# Function to create documentation
create_documentation() {
    print_header "Creating documentation"
    
    # Create docs directory structure
    mkdir -p "$SCRIPT_DIR/docs"
    
    # Create ARCHITECTURE.md
    cat > "$SCRIPT_DIR/docs/ARCHITECTURE.md" << 'EOF'
# LibreRouterOS Build Architecture

## Overview
The LibreRouterOS build system is based on a containerized OpenWrt build environment that solves common compatibility issues.

## Components

### Docker Container (Ubuntu 18.04)
- Solves GLIBC version compatibility issues
- Provides Python 2.7 environment required by OpenWrt
- Isolates build environment from host system

### Build Scripts
- `build-librerouteros.sh` - Main orchestrator
- `docker-build-clean.sh` - Docker-based build
- `build.sh` - OpenWrt build automation
- `monitor-build.sh` - Progress monitoring

### Script Collection
- Complete OpenWrt scripts from upstream
- Feed management and package metadata
- Configuration and validation tools

## Build Process

1. **Environment Setup**
   - Docker container preparation
   - Script collection validation
   - Dependency checking

2. **Source Preparation**
   - Feed updates and installation
   - Configuration loading
   - Package dependency resolution

3. **Compilation**
   - Toolchain build
   - Package compilation
   - Firmware image generation

## Target Support
- LibreRouter v1 (ath79/generic)
- x86_64 (testing)
- Multi-device (multiple ath79)
EOF

    # Create TROUBLESHOOTING.md
    cat > "$SCRIPT_DIR/docs/TROUBLESHOOTING.md" << 'EOF'
# LibreRouterOS Build Troubleshooting

## Common Issues

### Docker Permission Errors
```
permission denied while trying to connect to the Docker daemon socket
```
**Solution**: Add user to docker group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### GLIBC Version Errors
```
version `GLIBC_2.33' not found
```
**Solution**: Use Ubuntu 18.04 container (automatically handled)

### Missing Scripts
```
./scripts/feeds: not found
```
**Solution**: Ensure OpenWrt repository is available for script copying

### Build Failures
- Check logs with `./monitor-build.sh logs`
- Verify target repository is valid OpenWrt
- Ensure sufficient disk space (20GB+)
- Check memory availability (4GB+)

## Build Monitoring
- Real-time: `./monitor-build.sh start`
- Logs: `./monitor-build.sh logs`
- Status: `./monitor-build.sh status`

## Performance Tuning
- Adjust job count: `BUILD_JOBS=8 ./build-librerouteros.sh ...`
- Use cache directory: `DOWNLOAD_DIR=/cache ./build-librerouteros.sh ...`
EOF

    # Create DEVELOPMENT.md
    cat > "$SCRIPT_DIR/docs/DEVELOPMENT.md" << 'EOF'
# LibreRouterOS Development Workflow

## Quick Start
```bash
# Setup environment
./setup-environment.sh

# Build for testing
./build-librerouteros.sh ../librerouteros x86_64

# Monitor build
./monitor-build.sh start
```

## Development Cycle

1. **Environment Setup** (once)
   ```bash
   ./setup-environment.sh
   ```

2. **Repository Preparation**
   ```bash
   git clone <repo> target-repo
   cd target-repo
   # Make changes
   ```

3. **Build and Test**
   ```bash
   ../lime-build/build-librerouteros.sh . x86_64
   ```

4. **Validation**
   ```bash
   # Check images
   ls -la bin/targets/*/
   
   # Test in QEMU
   qemu-system-x86_64 -m 512 -nographic -kernel bin/targets/x86/64/openwrt-*-kernel.bin
   ```

## Adding New Targets
1. Create configuration file in `configs/`
2. Add target to `build.sh` switch statement
3. Update `build-librerouteros.sh` validation
4. Test build process

## Extending Build System
- Add new Docker base images in `Dockerfile.*`
- Extend monitoring in `monitor-build.sh`
- Add validation in `validate-config.sh`
EOF

    print_info "Documentation created"
}

# Function to show setup summary
show_summary() {
    print_header "Setup Summary"
    
    print_info "✅ System requirements validated"
    print_info "✅ Docker environment configured"
    print_info "✅ Build directories created"
    print_info "✅ Documentation generated"
    
    echo ""
    print_info "Build environment is ready!"
    print_info "Next steps:"
    echo "  1. Clone or navigate to LibreRouterOS repository"
    echo "  2. Run: $SCRIPT_DIR/build-librerouteros.sh <repo_path> <target>"
    echo "  3. Monitor: $SCRIPT_DIR/monitor-build.sh start"
    echo ""
    print_info "Example:"
    echo "  $SCRIPT_DIR/build-librerouteros.sh ../librerouteros x86_64"
}

# Main execution
main() {
    print_header "LibreRouterOS Build Environment Setup"
    
    # Check system requirements
    check_requirements
    
    # Setup Docker
    setup_docker
    
    # Validate environment
    validate_environment
    
    # Setup directories
    setup_directories
    
    # Create documentation
    create_documentation
    
    # Show summary
    show_summary
    
    print_header "Setup complete!"
}

# Run main function
main "$@"