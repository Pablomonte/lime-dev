#!/bin/bash

# Linux Platform Verification Script
# Validates Linux-specific requirements for lime-dev

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect Linux distribution
detect_linux_distro() {
    local distro="unknown"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        distro="$ID"
    elif [[ -f /etc/debian_version ]]; then
        distro="debian"
    elif [[ -f /etc/redhat-release ]]; then
        distro="rhel"
    elif [[ -f /etc/arch-release ]]; then
        distro="arch"
    fi
    
    log_info "Detected Linux distribution: $distro"
    echo "$distro"
}

# Check package manager availability
check_package_manager() {
    local distro="$1"
    local pm_available=false
    
    case "$distro" in
        ubuntu|debian)
            if command_exists "apt-get"; then
                log_success "Package manager: apt-get available"
                pm_available=true
            else
                log_error "Package manager: apt-get missing"
            fi
            ;;
        fedora|rhel|centos)
            if command_exists "dnf"; then
                log_success "Package manager: dnf available"
                pm_available=true
            elif command_exists "yum"; then
                log_success "Package manager: yum available"
                pm_available=true
            else
                log_error "Package manager: neither dnf nor yum available"
            fi
            ;;
        arch|manjaro)
            if command_exists "pacman"; then
                log_success "Package manager: pacman available"
                pm_available=true
            else
                log_error "Package manager: pacman missing"
            fi
            ;;
        *)
            log_warning "Package manager: unknown distribution, cannot verify"
            ;;
    esac
    
    return $($pm_available && echo 0 || echo 1)
}

# Check kernel version and features
check_kernel_features() {
    local kernel_version
    kernel_version=$(uname -r)
    log_info "Kernel version: $kernel_version"
    
    # Check for KVM support
    if [[ -e /dev/kvm ]]; then
        log_success "KVM: /dev/kvm device available"
        
        # Check KVM permissions
        if [[ -r /dev/kvm && -w /dev/kvm ]]; then
            log_success "KVM: Device accessible"
        else
            log_warning "KVM: Device exists but may need permission changes"
        fi
    else
        log_warning "KVM: /dev/kvm not available (virtualization disabled or not supported)"
    fi
    
    # Check for TUN/TAP support
    if [[ -e /dev/net/tun ]]; then
        log_success "TUN/TAP: /dev/net/tun available"
    else
        log_warning "TUN/TAP: /dev/net/tun missing (may affect networking)"
    fi
    
    # Check for bridge support
    if [[ -d /sys/module/bridge ]]; then
        log_success "Bridge: Kernel module loaded"
    elif modinfo bridge >/dev/null 2>&1; then
        log_info "Bridge: Kernel module available but not loaded"
    else
        log_warning "Bridge: Kernel module not available"
    fi
}

# Check system resources
check_system_resources() {
    # Check memory
    local total_mem
    total_mem=$(free -m | awk '/^Mem:/ {print $2}')
    log_info "Total memory: ${total_mem}MB"
    
    if [[ $total_mem -ge 4096 ]]; then
        log_success "Memory: Sufficient for development (${total_mem}MB >= 4GB)"
    elif [[ $total_mem -ge 2048 ]]; then
        log_warning "Memory: Limited but usable (${total_mem}MB)"
    else
        log_error "Memory: Insufficient for development (${total_mem}MB < 2GB)"
    fi
    
    # Check disk space
    local available_space
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "Available disk space: ${available_space}GB"
    
    if [[ $available_space -ge 10 ]]; then
        log_success "Disk space: Sufficient (${available_space}GB >= 10GB)"
    elif [[ $available_space -ge 5 ]]; then
        log_warning "Disk space: Limited (${available_space}GB)"
    else
        log_error "Disk space: Insufficient (${available_space}GB < 5GB)"
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    log_info "CPU cores: $cpu_cores"
    
    if [[ $cpu_cores -ge 4 ]]; then
        log_success "CPU: Sufficient cores for parallel builds ($cpu_cores)"
    else
        log_warning "CPU: Limited cores ($cpu_cores)"
    fi
}

# Check development packages
check_development_packages() {
    local distro="$1"
    local essential_packages=()
    local missing_packages=()
    
    # Define essential packages by distribution
    case "$distro" in
        ubuntu|debian)
            essential_packages=("build-essential" "git" "curl" "wget" "unzip" "python3" "python3-pip")
            ;;
        fedora|rhel|centos)
            essential_packages=("gcc" "gcc-c++" "make" "git" "curl" "wget" "unzip" "python3" "python3-pip")
            ;;
        arch|manjaro)
            essential_packages=("base-devel" "git" "curl" "wget" "unzip" "python" "python-pip")
            ;;
        *)
            log_warning "Unknown distribution, skipping package check"
            return 0
            ;;
    esac
    
    # Check if packages are installed
    for package in "${essential_packages[@]}"; do
        case "$distro" in
            ubuntu|debian)
                if dpkg -l "$package" >/dev/null 2>&1; then
                    log_success "Package: $package installed"
                else
                    log_warning "Package: $package missing"
                    missing_packages+=("$package")
                fi
                ;;
            fedora|rhel|centos)
                if rpm -q "$package" >/dev/null 2>&1; then
                    log_success "Package: $package installed"
                else
                    log_warning "Package: $package missing"
                    missing_packages+=("$package")
                fi
                ;;
            arch|manjaro)
                if pacman -Qi "$package" >/dev/null 2>&1; then
                    log_success "Package: $package installed"
                else
                    log_warning "Package: $package missing"
                    missing_packages+=("$package")
                fi
                ;;
        esac
    done
    
    # Report missing packages
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_warning "Missing packages: ${missing_packages[*]}"
        
        # Provide installation command
        case "$distro" in
            ubuntu|debian)
                log_info "Install with: sudo apt-get install ${missing_packages[*]}"
                ;;
            fedora)
                log_info "Install with: sudo dnf install ${missing_packages[*]}"
                ;;
            rhel|centos)
                log_info "Install with: sudo yum install ${missing_packages[*]}"
                ;;
            arch|manjaro)
                log_info "Install with: sudo pacman -S ${missing_packages[*]}"
                ;;
        esac
    else
        log_success "All essential packages installed"
    fi
}

# Check QEMU and virtualization
check_qemu_setup() {
    # Check QEMU installation
    if command_exists "qemu-system-x86_64"; then
        local qemu_version
        qemu_version=$(qemu-system-x86_64 --version | head -1)
        log_success "QEMU: $qemu_version"
    else
        log_error "QEMU: qemu-system-x86_64 not installed"
        return 1
    fi
    
    # Check virtualization support
    if grep -q "vmx\|svm" /proc/cpuinfo; then
        log_success "Virtualization: CPU supports virtualization"
    else
        log_warning "Virtualization: CPU may not support virtualization"
    fi
    
    # Check if user is in kvm group
    if groups | grep -q "kvm"; then
        log_success "User groups: User in kvm group"
    else
        log_warning "User groups: User not in kvm group"
        log_info "Add with: sudo usermod -a -G kvm \$USER"
    fi
}

# Check network tools and configuration
check_network_setup() {
    # Check network tools
    local net_tools=("ip" "brctl" "iptables")
    
    for tool in "${net_tools[@]}"; do
        if command_exists "$tool"; then
            log_success "Network tool: $tool available"
        else
            log_warning "Network tool: $tool missing"
        fi
    done
    
    # Check if bridge-utils is installed
    if command_exists "brctl"; then
        log_success "Bridge utilities: Available"
    else
        log_warning "Bridge utilities: Missing (install bridge-utils)"
    fi
    
    # Check network namespaces support
    if [[ -d /var/run/netns ]]; then
        log_success "Network namespaces: Supported"
    else
        log_info "Network namespaces: Directory not present (may be created on demand)"
    fi
}

# Check SELinux/AppArmor status
check_security_frameworks() {
    # Check SELinux
    if command_exists "getenforce"; then
        local selinux_status
        selinux_status=$(getenforce 2>/dev/null || echo "Unknown")
        log_info "SELinux status: $selinux_status"
        
        if [[ "$selinux_status" == "Enforcing" ]]; then
            log_warning "SELinux: Enforcing mode may cause issues with development"
        fi
    fi
    
    # Check AppArmor
    if command_exists "aa-status"; then
        local apparmor_status
        apparmor_status=$(aa-status --enabled 2>/dev/null && echo "Enabled" || echo "Disabled")
        log_info "AppArmor status: $apparmor_status"
    fi
}

# Check systemd services
check_systemd_services() {
    if command_exists "systemctl"; then
        log_success "Systemd: Available"
        
        # Check if Docker service is available
        if systemctl list-unit-files | grep -q "docker.service"; then
            local docker_status
            docker_status=$(systemctl is-active docker 2>/dev/null || echo "inactive")
            log_info "Docker service: $docker_status"
        fi
    else
        log_info "Systemd: Not available (using different init system)"
    fi
}

# Main Linux verification
main() {
    echo "================================================================================"
    echo "LINUX PLATFORM VERIFICATION"
    echo "================================================================================"
    
    # Detect distribution
    local distro
    distro=$(detect_linux_distro)
    
    # Run checks
    check_package_manager "$distro"
    check_kernel_features
    check_system_resources
    check_development_packages "$distro"
    check_qemu_setup
    check_network_setup
    check_security_frameworks
    check_systemd_services
    
    echo ""
    log_success "Linux platform verification completed"
    
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi