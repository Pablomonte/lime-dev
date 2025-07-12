#!/usr/bin/env bash
#
# LibreMesh Development Environment Setup
# Fetches repositories, installs dependencies, and configures QEMU development
# Uses centralized configuration for reproducible infrastructure replication
#

set -e

WORK_DIR="$(pwd)"
LIME_BUILD_DIR="$WORK_DIR"
CONFIG_FILE="$LIME_BUILD_DIR/configs/versions.conf"
RELEASE_MODE="${LIME_RELEASE_MODE:-false}"

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1" >&2
}

# Parse configuration file
parse_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    print_info "Using configuration: $CONFIG_FILE"
    print_info "Release mode: $RELEASE_MODE"
}

# Get repository configuration
get_repo_config() {
    local repo_name="$1"
    local section="repositories"
    
    # Check if we should use release overrides
    if [[ "$RELEASE_MODE" == "true" ]]; then
        local release_key="${repo_name}_release"
        if grep -q "^${release_key}=" "$CONFIG_FILE"; then
            section="release_overrides"
            repo_name="$release_key"
        fi
    fi
    
    # Extract configuration
    local config=$(grep "^${repo_name}=" "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$config" ]]; then
        echo "${config#*=}"
    else
        print_error "No configuration found for repository: $1"
        return 1
    fi
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

# Clone or update a single repository based on configuration
clone_repository() {
    local repo_name="$1"
    local config=$(get_repo_config "$repo_name")
    
    if [[ -z "$config" ]]; then
        print_warning "Skipping $repo_name: no configuration found"
        return 0
    fi
    
    IFS='|' read -r repo_url branch remote_name <<< "$config"
    local dir_name="${repo_name/_/-}"  # Convert underscore to dash for directory
    
    print_info "Processing $repo_name -> $dir_name"
    print_info "  URL: $repo_url"
    print_info "  Branch: $branch"
    print_info "  Remote: $remote_name"
    
    if [[ ! -d "$dir_name" ]]; then
        print_info "Cloning $dir_name..."
        if [[ "$repo_name" == "openwrt" ]]; then
            # Use developer-specified OpenWrt clone command
            print_info "  Using developer-specified command: git clone -b v24.10.1 --single-branch https://git.openwrt.org/openwrt/openwrt.git"
            git clone -b v24.10.1 --single-branch https://git.openwrt.org/openwrt/openwrt.git "$dir_name"
        elif [[ "$branch" =~ ^v[0-9] ]]; then
            # Handle version tags
            git clone -b "$branch" --single-branch "$repo_url" "$dir_name"
        else
            # Handle regular branches
            git clone -b "$branch" "$repo_url" "$dir_name"
        fi
        
        # Set up remote tracking if different from origin
        if [[ "$remote_name" != "origin" ]]; then
            cd "$dir_name"
            git remote rename origin "$remote_name"
            cd ..
        fi
    else
        print_info "Repository $dir_name already exists"
        cd "$dir_name"
        
        # Add remote if it doesn't exist
        if ! git remote | grep -q "$remote_name"; then
            git remote add "$remote_name" "$repo_url"
        fi
        
        # Fetch and update if not on a tag
        git fetch "$remote_name"
        if [[ ! "$branch" =~ ^v[0-9] ]]; then
            local current_branch=$(git branch --show-current 2>/dev/null || echo "")
            if [[ "$current_branch" == "$branch" ]]; then
                git pull "$remote_name" "$branch"
            else
                print_info "  Currently on different branch: $current_branch"
            fi
        fi
        cd ..
    fi
}

# Clone or update all repositories
clone_repositories() {
    print_info "Setting up repositories in repos/ directory..."
    
    # Ensure repos directory exists
    mkdir -p repos
    cd repos
    
    # Process each repository from configuration
    local repos=("lime_app" "lime_packages" "librerouteros" "kconfig_utils" "openwrt")
    
    for repo in "${repos[@]}"; do
        clone_repository "$repo"
    done
    
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

# Show environment information
show_environment_info() {
    print_info "Environment Information:"
    echo "  Release mode: $RELEASE_MODE"
    echo "  Configuration: $CONFIG_FILE"
    echo "  Working directory: $LIME_BUILD_DIR"
    
    if [[ "$RELEASE_MODE" == "true" ]]; then
        print_warning "Running in RELEASE MODE - using release repository overrides"
    fi
}

# Main execution
main() {
    print_info "Setting up LibreMesh development environment..."
    
    check_directory
    parse_config
    show_environment_info
    install_dependencies
    clone_repositories
    setup_lime_app
    setup_lime_packages
    setup_system
    download_images
    create_dev_script
    
    if test_setup; then
        print_success "Setup completed successfully!"
        echo ""
        echo "Development commands:"
        echo "  ./dev.sh start    - Start QEMU development environment"
        echo "  ./dev.sh deploy   - Deploy changes"
        echo "  ./dev.sh stop     - Stop environment"
        echo ""
        echo "Access lime-app at: http://10.13.0.1/app/"
        echo ""
        if [[ "$RELEASE_MODE" == "true" ]]; then
            print_info "Release repositories have been set up for pre-release testing"
        fi
        echo "Note: You may need to log out and back in for group changes to take effect."
    else
        print_error "Setup completed with issues. Check the output above."
        exit 1
    fi
}

main "$@"