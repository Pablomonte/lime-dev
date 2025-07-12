#!/usr/bin/env bash
#
# Check Current Setup Status
# Non-invasive assessment of lime-build environment
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$LIME_BUILD_DIR/configs/versions.conf"

print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "[✓] $1"
}

print_warning() {
    echo "[⚠] $1"
}

print_error() {
    echo "[✗] $1"
}

print_section() {
    echo ""
    echo "=== $1 ==="
}

# Check dependencies
check_dependencies() {
    print_section "System Dependencies"
    
    local deps=(qemu-system-x86 qemu-utils bridge-utils dnsmasq screen curl wget git build-essential nodejs npm cpio tar gzip)
    local missing=0
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1 || dpkg -l 2>/dev/null | grep -q "^ii.*$dep"; then
            print_success "$dep installed"
        else
            print_error "$dep missing"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        print_success "All dependencies satisfied"
    else
        print_warning "$missing dependencies missing"
        echo "Install with: sudo apt-get install [missing packages]"
    fi
}

# Check repositories
check_repositories() {
    print_section "Repository Status"
    
    cd "$LIME_BUILD_DIR"
    
    if [[ ! -d "repos" ]]; then
        print_error "repos/ directory not found"
        return 1
    fi
    
    cd repos
    
    local repos=(lime-app lime-packages librerouteros kconfig-utils openwrt)
    
    for repo in "${repos[@]}"; do
        if [[ -d "$repo" ]]; then
            cd "$repo"
            local branch=$(git branch --show-current 2>/dev/null || echo "detached")
            local status=$(git status --porcelain | wc -l)
            local commits_ahead=$(git log --oneline origin/$branch..$branch 2>/dev/null | wc -l || echo "0")
            
            if [[ $status -gt 0 ]]; then
                print_warning "$repo: $branch ($status changes, $commits_ahead ahead)"
            elif [[ $commits_ahead -gt 0 ]]; then
                print_warning "$repo: $branch ($commits_ahead commits ahead)"
            else
                print_success "$repo: $branch (clean)"
            fi
            cd ..
        else
            print_error "$repo: not found"
        fi
    done
    
    cd "$LIME_BUILD_DIR"
}

# Check system configuration
check_system() {
    print_section "System Configuration"
    
    # Check virtualization
    if grep -q "vmx\|svm" /proc/cpuinfo; then
        print_success "Hardware virtualization supported"
        
        if groups | grep -q kvm; then
            print_success "User in kvm group"
        else
            print_warning "User not in kvm group (add with: sudo usermod -a -G kvm $USER)"
        fi
        
        if lsmod | grep -q "^kvm"; then
            print_success "KVM modules loaded"
        else
            print_warning "KVM modules not loaded"
        fi
    else
        print_warning "No hardware virtualization support"
    fi
    
    # Check network modules
    for module in bridge tun; do
        if lsmod | grep -q "^$module"; then
            print_success "$module module loaded"
        else
            print_warning "$module module not loaded"
        fi
    done
    
    # Check disk space
    local available=$(df "$LIME_BUILD_DIR" | tail -1 | awk '{print int($4/1024/1024)}')
    if [[ $available -ge 10 ]]; then
        print_success "Disk space: ${available}GB available"
    else
        print_warning "Disk space: ${available}GB available (10GB+ recommended)"
    fi
    
    # Check memory
    local memory=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024/1024)}')
    if [[ $memory -ge 4 ]]; then
        print_success "Memory: ${memory}GB total"
    else
        print_warning "Memory: ${memory}GB total (4GB+ recommended)"
    fi
}

# Check build readiness
check_build_readiness() {
    print_section "Build Readiness"
    
    # Check if librerouteros build script exists
    if [[ -f "repos/librerouteros/librerouteros_build.sh" ]]; then
        print_success "LibreRouterOS build script found"
    else
        print_error "LibreRouterOS build script missing"
    fi
    
    # Check if wrapper script exists
    if [[ -f "scripts/librerouteros-wrapper.sh" ]]; then
        print_success "Build wrapper script found"
    else
        print_error "Build wrapper script missing"
    fi
    
    # Check if docker build script exists
    if [[ -f "scripts/docker-build.sh" ]]; then
        print_success "Docker build script found"
    else
        print_error "Docker build script missing"
    fi
    
    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            print_success "Docker running"
        else
            print_warning "Docker installed but not running"
        fi
    else
        print_warning "Docker not installed"
    fi
    
    # Check configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        print_success "Configuration file found"
    else
        print_error "Configuration file missing: $CONFIG_FILE"
    fi
}

# Show recommendations
show_recommendations() {
    print_section "Recommendations"
    
    echo "Based on the current setup:"
    echo ""
    
    if [[ ! -d "repos" ]] || [[ ! -d "repos/librerouteros" ]]; then
        echo "• Run setup: ./scripts/setup-lime-dev-safe.sh"
    fi
    
    if ! groups | grep -q kvm; then
        echo "• Add user to kvm group: sudo usermod -a -G kvm $USER"
        echo "  (then logout and login again)"
    fi
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "• Install Docker for containerized builds"
    fi
    
    local available=$(df "$LIME_BUILD_DIR" | tail -1 | awk '{print int($4/1024/1024)}')
    if [[ $available -lt 10 ]]; then
        echo "• Free up disk space (need 10GB+, have ${available}GB)"
    fi
    
    echo ""
    echo "Ready to build? Try:"
    echo "  ./scripts/librerouteros-wrapper.sh librerouter-v1"
    echo "  ./scripts/docker-build.sh librerouter-v1"
}

# Main execution
main() {
    print_info "LibreMesh Build Environment Status Check"
    print_info "Working directory: $LIME_BUILD_DIR"
    
    check_dependencies
    check_repositories  
    check_system
    check_build_readiness
    show_recommendations
    
    echo ""
    print_info "Status check complete"
}

main "$@"