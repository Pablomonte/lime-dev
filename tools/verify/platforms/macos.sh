#!/bin/bash

# macOS Platform Verification Script
# Validates macOS-specific requirements for lime-dev

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

# Check macOS version
check_macos_version() {
    local version
    version=$(sw_vers -productVersion)
    log_info "macOS version: $version"
    
    # Extract major version
    local major
    major=$(echo "$version" | cut -d. -f1)
    
    if [[ $major -ge 11 ]]; then
        log_success "macOS: Version $version supported"
    else
        log_warning "macOS: Version $version may have compatibility issues"
    fi
}

# Check Homebrew
check_homebrew() {
    if command_exists "brew"; then
        local brew_version
        brew_version=$(brew --version | head -1)
        log_success "Homebrew: $brew_version"
        
        # Check if Homebrew is up to date
        log_info "Checking Homebrew status..."
        if brew doctor >/dev/null 2>&1; then
            log_success "Homebrew: Configuration healthy"
        else
            log_warning "Homebrew: May have configuration issues"
        fi
    else
        log_error "Homebrew: Not installed"
        log_info "Install with: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
}

# Check development tools
check_xcode_tools() {
    if xcode-select -p >/dev/null 2>&1; then
        local xcode_path
        xcode_path=$(xcode-select -p)
        log_success "Xcode Command Line Tools: Installed at $xcode_path"
    else
        log_error "Xcode Command Line Tools: Not installed"
        log_info "Install with: xcode-select --install"
        return 1
    fi
    
    # Check for essential tools
    local tools=("gcc" "make" "git")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_success "Tool: $tool available"
        else
            log_error "Tool: $tool missing"
        fi
    done
}

# Check QEMU installation
check_qemu_macos() {
    if command_exists "qemu-system-x86_64"; then
        local qemu_version
        qemu_version=$(qemu-system-x86_64 --version | head -1)
        log_success "QEMU: $qemu_version"
    else
        log_warning "QEMU: Not installed"
        log_info "Install with: brew install qemu"
    fi
    
    # Note about performance
    log_warning "Note: QEMU on macOS may have reduced performance compared to Linux"
}

# Check system resources
check_system_resources() {
    # Check memory
    local total_mem
    total_mem=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2}')
    log_info "Total memory: $total_mem"
    
    # Check disk space
    local available_space
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "Available disk space: ${available_space}GB"
    
    if [[ $available_space -ge 10 ]]; then
        log_success "Disk space: Sufficient (${available_space}GB >= 10GB)"
    else
        log_warning "Disk space: Limited (${available_space}GB)"
    fi
}

# Main macOS verification
main() {
    echo "================================================================================" 
    echo "MACOS PLATFORM VERIFICATION"
    echo "================================================================================" 
    
    check_macos_version
    check_homebrew
    check_xcode_tools
    check_qemu_macos
    check_system_resources
    
    echo ""
    log_success "macOS platform verification completed"
    
    return 0
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi