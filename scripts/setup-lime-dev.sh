#!/usr/bin/env bash
#
# LibreMesh Development Environment Setup
# Fetches repositories, installs dependencies, and configures QEMU development
#

set -e

WORK_DIR="$(pwd)"
LIME_BUILD_DIR="$WORK_DIR"

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

# Check if running from lime-build directory
check_directory() {
    if [[ ! "$(basename "$PWD")" == "lime-build" ]]; then
        print_error "This script should be run from the lime-build directory"
        exit 1
    fi
}

# Install system dependencies
install_dependencies() {
    print_info "Installing system dependencies..."
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y \
            qemu-system-x86 \
            qemu-utils \
            bridge-utils \
            dnsmasq \
            screen \
            curl \
            wget \
            git \
            build-essential \
            nodejs \
            npm \
            cpio \
            tar \
            gzip
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y \
            qemu-kvm \
            qemu-img \
            bridge-utils \
            dnsmasq \
            screen \
            curl \
            wget \
            git \
            gcc \
            make \
            nodejs \
            npm \
            cpio \
            tar \
            gzip
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y \
            qemu-system-x86 \
            qemu-img \
            bridge-utils \
            dnsmasq \
            screen \
            curl \
            wget \
            git \
            gcc \
            make \
            nodejs \
            npm \
            cpio \
            tar \
            gzip
    else
        print_error "Unsupported package manager. Install dependencies manually:"
        print_error "qemu-system-x86_64, bridge-utils, dnsmasq, screen, nodejs, npm, git"
        exit 1
    fi
}

# Clone or update repositories
clone_repositories() {
    print_info "Setting up repositories in repos/ directory..."
    
    # Ensure repos directory exists
    mkdir -p repos
    cd repos
    
    # LibreMesh web interface
    if [[ ! -d "lime-app" ]]; then
        print_info "Cloning lime-app..."
        git clone https://github.com/libremesh/lime-app.git
    else
        print_info "Updating lime-app..."
        cd lime-app && git fetch --all && git pull origin master && cd ..
    fi
    
    # LibreMesh packages
    if [[ ! -d "lime-packages" ]]; then
        print_info "Cloning lime-packages..."
        git clone https://github.com/libremesh/lime-packages.git
    else
        print_info "Updating lime-packages..."
        cd lime-packages && git fetch --all && git pull origin master && cd ..
    fi
    
    # LibreRouterOS firmware
    if [[ ! -d "librerouteros" ]]; then
        print_info "Cloning librerouteros..."
        git clone https://gitlab.com/librerouter/librerouteros.git
    else
        print_info "Updating librerouteros..."
        cd librerouteros && git fetch --all && git pull origin librerouter-1.5 && cd ..
    fi
    
    # OpenWrt source (specific version)
    if [[ ! -d "openwrt" ]]; then
        print_info "Cloning OpenWrt v24.10.1..."
        git clone -b v24.10.1 --single-branch https://git.openwrt.org/openwrt/openwrt.git
    else
        print_info "OpenWrt already exists (specific version v24.10.1)"
    fi
    
    # kconfig-utils if needed
    if [[ ! -d "kconfig-utils" ]]; then
        print_info "Cloning kconfig-utils..."
        git clone https://github.com/gustavoz/kconfig-utils.git
    else
        print_info "Updating kconfig-utils..."
        cd kconfig-utils && git fetch --all && git pull origin master && cd ..
    fi
    
    cd "$LIME_BUILD_DIR"
}

# Setup lime-app
setup_lime_app() {
    print_info "Setting up lime-app..."
    
    cd "$LIME_BUILD_DIR/repos/lime-app"
    
    if [[ ! -d "node_modules" ]]; then
        npm install
    fi
    
    # Make scripts executable
    chmod +x scripts/*.sh 2>/dev/null || true
    
    cd "$LIME_BUILD_DIR"
}

# Setup lime-packages
setup_lime_packages() {
    print_info "Setting up lime-packages..."
    
    cd "$LIME_BUILD_DIR/repos/lime-packages"
    
    # Make tools executable
    chmod +x tools/* 2>/dev/null || true
    
    cd "$LIME_BUILD_DIR"
}

# Setup system configuration
setup_system() {
    print_info "Setting up system configuration..."
    
    # Load kernel modules
    sudo modprobe bridge 2>/dev/null || true
    sudo modprobe tun 2>/dev/null || true
    
    # KVM setup
    if grep -q "vmx\|svm" /proc/cpuinfo; then
        sudo modprobe kvm-intel 2>/dev/null || sudo modprobe kvm-amd 2>/dev/null || true
        
        # Add user to kvm group
        sudo usermod -a -G kvm "$USER" 2>/dev/null || true
    fi
}

# Download images (if needed)
download_images() {
    print_info "Checking for LibreMesh images..."
    
    cd "$LIME_BUILD_DIR/repos/lime-packages"
    
    if [[ ! -d "build" ]]; then
        mkdir -p build
    fi
    
    # Check if we need to download images
    local has_images=false
    if ls build/*.img.gz build/*.tar.gz build/*.bin 2>/dev/null | grep -q .; then
        has_images=true
    fi
    
    if [[ "$has_images" == "false" ]]; then
        print_info "No images found. You'll need to build them or download from releases."
        print_info "To build: run the build scripts in lime-packages"
        print_info "To download: get releases from GitHub"
    fi
    
    cd "$LIME_BUILD_DIR"
}

# Test QEMU setup
test_setup() {
    print_info "Testing QEMU setup..."
    
    cd "$LIME_BUILD_DIR/repos/lime-app"
    
    # Test if qemu configs work
    if npm run qemu:configs >/dev/null 2>&1; then
        print_info "QEMU configuration working"
    else
        print_error "QEMU configuration failed"
        return 1
    fi
    
    cd "$LIME_BUILD_DIR"
}

# Create development script
create_dev_script() {
    cat > "$LIME_BUILD_DIR/dev.sh" << 'EOF'
#!/usr/bin/env bash
# LibreMesh development helper

cd "$(dirname "$0")/../repos/lime-app"

case "${1:-help}" in
    start)
        npm run qemu:start
        ;;
    stop)
        npm run qemu:stop
        ;;
    deploy)
        npm run deploy:qemu
        ;;
    status)
        npm run qemu:status
        ;;
    configs)
        npm run qemu:configs
        ;;
    build)
        npm run build:production
        ;;
    help)
        echo "LibreMesh Development Commands:"
        echo "  ./dev.sh start    - Start QEMU development environment"
        echo "  ./dev.sh stop     - Stop QEMU"
        echo "  ./dev.sh deploy   - Deploy lime-app changes to QEMU"
        echo "  ./dev.sh status   - Check QEMU status"
        echo "  ./dev.sh configs  - Show available configurations"
        echo "  ./dev.sh build    - Build lime-app"
        echo ""
        echo "Access: http://10.13.0.1/app/"
        echo "Console: sudo screen -r libremesh"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use './dev.sh help' for available commands"
        exit 1
        ;;
esac
EOF

    chmod +x "$LIME_BUILD_DIR/dev.sh"
}

# Main execution
main() {
    print_info "Setting up LibreMesh development environment..."
    
    check_directory
    install_dependencies
    clone_repositories
    setup_lime_app
    setup_lime_packages
    setup_system
    download_images
    create_dev_script
    
    if test_setup; then
        print_info "Setup completed successfully!"
        echo ""
        echo "Development commands:"
        echo "  ./dev.sh start    - Start QEMU development environment"
        echo "  ./dev.sh deploy   - Deploy changes"
        echo "  ./dev.sh stop     - Stop environment"
        echo ""
        echo "Access lime-app at: http://10.13.0.1/app/"
        echo ""
        echo "Note: You may need to log out and back in for group changes to take effect."
    else
        print_error "Setup completed with issues. Check the output above."
        exit 1
    fi
}

main "$@"