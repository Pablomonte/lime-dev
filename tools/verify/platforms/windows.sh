#!/bin/bash

# Windows/WSL Platform Verification Script
# Validates Windows/WSL-specific requirements for lime-dev

set -euo pipefail

# Colors for output (may not work in all Windows terminals)
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

# Detect Windows environment
detect_windows_environment() {
    local env_type="unknown"
    
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        env_type="WSL2"
        log_info "Environment: WSL2 ($WSL_DISTRO_NAME)"
    elif [[ "$OSTYPE" == "msys" ]]; then
        env_type="MSYS2"
        log_info "Environment: MSYS2/Git Bash"
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        env_type="Cygwin"
        log_info "Environment: Cygwin"
    else
        log_warning "Environment: Unknown Windows environment"
    fi
    
    echo "$env_type"
}

# Check WSL-specific features
check_wsl_features() {
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        log_warning "WSL: Not running in WSL environment"
        return 1
    fi
    
    log_success "WSL: Running in $WSL_DISTRO_NAME"
    
    # Check WSL version
    if [[ -n "${WSL_INTEROP:-}" ]]; then
        log_success "WSL: WSL2 detected (better performance)"
    else
        log_warning "WSL: WSL1 detected (limited features)"
    fi
    
    # Check if systemd is available in WSL
    if command_exists "systemctl"; then
        log_success "WSL: systemd available"
    else
        log_info "WSL: systemd not available (older WSL or disabled)"
    fi
    
    # Check Windows integration
    if command_exists "cmd.exe"; then
        log_success "WSL: Windows integration available"
    else
        log_warning "WSL: Windows integration not available"
    fi
}

# Check package manager for WSL
check_wsl_package_manager() {
    local distro=""
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        distro="$ID"
    fi
    
    case "$distro" in
        ubuntu|debian)
            if command_exists "apt-get"; then
                log_success "Package manager: apt-get available"
            else
                log_error "Package manager: apt-get missing"
                return 1
            fi
            ;;
        fedora|rhel|centos)
            if command_exists "dnf" || command_exists "yum"; then
                log_success "Package manager: dnf/yum available"
            else
                log_error "Package manager: dnf/yum missing"
                return 1
            fi
            ;;
        *)
            log_warning "Package manager: Unknown distribution in WSL"
            ;;
    esac
}

# Check virtualization in Windows
check_windows_virtualization() {
    log_info "Checking Windows virtualization support..."
    
    # In WSL, we can't directly check Windows virtualization
    # but we can check if nested virtualization works
    if [[ -e /dev/kvm ]]; then
        log_success "Virtualization: KVM available (nested virtualization enabled)"
    else
        log_warning "Virtualization: KVM not available"
        log_info "Enable nested virtualization in Windows: Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform"
    fi
    
    # Check for Hyper-V integration
    if [[ -d /sys/bus/vmbus ]]; then
        log_success "Hyper-V: Integration services detected"
    else
        log_info "Hyper-V: Integration services not detected"
    fi
}

# Check Windows-specific tools
check_windows_tools() {
    # Check if we can access Windows tools from WSL
    if command_exists "powershell.exe"; then
        log_success "Windows tools: PowerShell accessible from WSL"
    else
        log_warning "Windows tools: PowerShell not accessible"
    fi
    
    if command_exists "wsl.exe"; then
        log_success "Windows tools: WSL command available"
    else
        log_warning "Windows tools: WSL command not available"
    fi
    
    # Check for Docker Desktop integration
    if command_exists "docker"; then
        local docker_context
        docker_context=$(docker context show 2>/dev/null || echo "unknown")
        if [[ "$docker_context" == "desktop-linux" ]]; then
            log_success "Docker: Docker Desktop integration active"
        else
            log_info "Docker: $docker_context context"
        fi
    else
        log_warning "Docker: Not available (install Docker Desktop for Windows)"
    fi
}

# Check file system performance
check_filesystem_performance() {
    log_info "Checking file system performance..."
    
    # Check if we're in Windows filesystem vs Linux filesystem
    local current_path
    current_path=$(pwd)
    
    if [[ "$current_path" == /mnt/c/* ]]; then
        log_warning "File system: Working in Windows filesystem (slower performance)"
        log_info "Consider moving project to Linux filesystem (e.g., /home/user/)"
    else
        log_success "File system: Working in Linux filesystem (better performance)"
    fi
    
    # Quick write/read test
    local test_file="/tmp/fs_test_$$"
    local start_time end_time duration
    
    start_time=$(date +%s%N)
    echo "test" > "$test_file"
    cat "$test_file" > /dev/null
    rm -f "$test_file"
    end_time=$(date +%s%N)
    
    duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    log_info "File system: Basic I/O test took ${duration}ms"
}

# Check network configuration
check_windows_networking() {\n    log_info \"Checking network configuration...\"\n    \n    # Check if we can reach external networks\n    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then\n        log_success \"Network: External connectivity available\"\n    else\n        log_warning \"Network: External connectivity issues\"\n    fi\n    \n    # Check localhost connectivity\n    if ping -c 1 127.0.0.1 >/dev/null 2>&1; then\n        log_success \"Network: Localhost accessible\"\n    else\n        log_error \"Network: Localhost not accessible\"\n    fi\n    \n    # Check if Windows firewall might be blocking\n    log_info \"Note: Windows Firewall may need configuration for QEMU networking\"\n}

# Check development environment
check_windows_dev_environment() {
    # Check for essential development tools
    local tools=("git" "make" "gcc" "python3")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_success "Dev tool: $tool available"
        else
            log_warning "Dev tool: $tool missing"
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_info "Install missing tools with: sudo apt-get install ${missing_tools[*]}"
    fi
    
    # Check for Node.js (often needed for development)
    if command_exists "node"; then
        local node_version
        node_version=$(node --version)
        log_success "Node.js: $node_version available"
    else
        log_warning "Node.js: Not available"
    fi
}

# Main Windows verification
main() {
    echo "================================================================================"
    echo "WINDOWS/WSL PLATFORM VERIFICATION"
    echo "================================================================================"
    
    local env_type
    env_type=$(detect_windows_environment)
    
    # Run appropriate checks based on environment
    case "$env_type" in
        "WSL2")
            check_wsl_features
            check_wsl_package_manager
            check_windows_virtualization
            check_windows_tools
            check_filesystem_performance
            check_windows_networking
            check_windows_dev_environment
            ;;
        "MSYS2"|"Cygwin")
            log_warning "MSYS2/Cygwin: Limited support for lime-dev"
            log_info "Consider using WSL2 for better compatibility"
            check_windows_dev_environment
            ;;
        *)
            log_error "Unknown Windows environment - verification limited"
            ;;
    esac
    
    echo ""
    log_success "Windows platform verification completed"
    
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi