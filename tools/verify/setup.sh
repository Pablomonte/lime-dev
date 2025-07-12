#!/bin/bash

# Master Setup Verification Script
# Validates complete development environment setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIME_DEV_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"

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

# Verification results
declare -a PASSED_CHECKS=()
declare -a FAILED_CHECKS=()
declare -a WARNING_CHECKS=()

# Add result
add_result() {
    local status="$1"
    local check="$2"
    local message="$3"
    
    case "$status" in
        "pass")
            PASSED_CHECKS+=("$check: $message")
            log_success "$check: $message"
            ;;
        "fail")
            FAILED_CHECKS+=("$check: $message")
            log_error "$check: $message"
            ;;
        "warn")
            WARNING_CHECKS+=("$check: $message")
            log_warning "$check: $message"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check platform detection
check_platform() {
    local platform=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists "apt-get"; then
            platform="ubuntu/debian"
        elif command_exists "yum" || command_exists "dnf"; then
            platform="rhel/centos/fedora"
        elif command_exists "pacman"; then
            platform="arch"
        else
            platform="linux (unknown)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        platform="macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        platform="windows"
    else
        platform="unknown"
    fi
    
    add_result "pass" "Platform Detection" "$platform"
    return 0
}

# Check basic system requirements
check_basic_requirements() {
    local requirements=("bash" "git" "make")
    local missing=()
    
    for req in "${requirements[@]}"; do
        if command_exists "$req"; then
            add_result "pass" "Basic Tool" "$req available"
        else
            add_result "fail" "Basic Tool" "$req missing"
            missing+=("$req")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        add_result "pass" "Basic Requirements" "All essential tools available"
        return 0
    else
        add_result "fail" "Basic Requirements" "Missing: ${missing[*]}"
        return 1
    fi
}

# Check development tools
check_development_tools() {
    local dev_tools=("gcc" "g++" "python3" "node" "npm")
    local available=()
    local missing=()
    
    for tool in "${dev_tools[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
            add_result "pass" "Dev Tool" "$tool available"
        else
            missing+=("$tool")
            add_result "warn" "Dev Tool" "$tool missing"
        fi
    done
    
    if [[ ${#available[@]} -ge 3 ]]; then
        add_result "pass" "Development Tools" "${#available[@]}/${#dev_tools[@]} tools available"
        return 0
    else
        add_result "warn" "Development Tools" "Limited development tools available"
        return 1
    fi
}

# Check QEMU and virtualization
check_qemu_virtualization() {
    if command_exists "qemu-system-x86_64"; then
        add_result "pass" "QEMU" "qemu-system-x86_64 available"
    else
        add_result "fail" "QEMU" "qemu-system-x86_64 missing"
        return 1
    fi
    
    # Check KVM support on Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -e /dev/kvm ]]; then
            add_result "pass" "KVM" "/dev/kvm device available"
        else
            add_result "warn" "KVM" "/dev/kvm not available (performance impact)"
        fi
        
        # Check if user is in kvm group
        if groups | grep -q "kvm"; then
            add_result "pass" "KVM Group" "User in kvm group"
        else
            add_result "warn" "KVM Group" "User not in kvm group (may need sudo)"
        fi
    fi
    
    return 0
}

# Check network tools
check_network_tools() {
    local net_tools=("ip" "brctl" "curl" "wget")
    local available=()
    local missing=()
    
    for tool in "${net_tools[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
            add_result "pass" "Network Tool" "$tool available"
        else
            missing+=("$tool")
            add_result "warn" "Network Tool" "$tool missing"
        fi
    done
    
    # Check for bridge-utils specifically
    if command_exists "brctl"; then
        add_result "pass" "Bridge Utils" "Network bridging supported"
    else
        add_result "warn" "Bridge Utils" "Network bridging may not work"
    fi
    
    return 0
}

# Check repository structure
check_repository_structure() {
    local required_dirs=("scripts" "configs" "docs")
    local optional_dirs=("repos" "cache" "logs" "tests")
    
    # Check required directories
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$LIME_DEV_ROOT/$dir" ]]; then
            add_result "pass" "Directory" "$dir/ exists"
        else
            add_result "fail" "Directory" "$dir/ missing"
        fi
    done
    
    # Check optional directories
    for dir in "${optional_dirs[@]}"; do
        if [[ -d "$LIME_DEV_ROOT/$dir" ]]; then
            add_result "pass" "Optional Directory" "$dir/ exists"
        else
            add_result "warn" "Optional Directory" "$dir/ missing (will be created)"
        fi
    done
    
    # Check main CLI script
    if [[ -x "$LIME_DEV_ROOT/scripts/lime" ]]; then
        add_result "pass" "Main CLI" "scripts/lime executable"
    elif [[ -f "$LIME_DEV_ROOT/scripts/lime" ]]; then
        add_result "warn" "Main CLI" "scripts/lime exists but not executable"
    else
        add_result "fail" "Main CLI" "scripts/lime missing"
    fi
    
    return 0
}

# Check managed repositories
check_managed_repos() {
    local repos=("lime-app" "lime-packages" "librerouteros")
    local existing=()
    local missing=()
    
    if [[ ! -d "$LIME_DEV_ROOT/repos" ]]; then
        add_result "warn" "Repositories" "repos/ directory missing"
        return 1
    fi
    
    for repo in "${repos[@]}"; do
        if [[ -d "$LIME_DEV_ROOT/repos/$repo" ]]; then
            existing+=("$repo")
            add_result "pass" "Repository" "$repo cloned"
            
            # Check if it's a git repository
            if [[ -d "$LIME_DEV_ROOT/repos/$repo/.git" ]]; then
                add_result "pass" "Git Repository" "$repo is valid git repo"
            else
                add_result "warn" "Git Repository" "$repo missing .git directory"
            fi
        else
            missing+=("$repo")
            add_result "warn" "Repository" "$repo not cloned"
        fi
    done
    
    if [[ ${#existing[@]} -gt 0 ]]; then
        add_result "pass" "Repository Status" "${#existing[@]}/${#repos[@]} repositories available"
    fi
    
    return 0
}

# Check build tools
check_build_tools() {
    # Check for build essentials
    local build_tools=("make" "gcc" "g++" "ld")
    local available=()
    
    for tool in "${build_tools[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
        fi
    done
    
    if [[ ${#available[@]} -ge 3 ]]; then
        add_result "pass" "Build Tools" "Essential build tools available"
    else
        add_result "warn" "Build Tools" "Limited build environment"
    fi
    
    # Check for Docker
    if command_exists "docker"; then
        add_result "pass" "Docker" "Docker available for containerized builds"
        
        # Check if Docker daemon is running
        if docker info >/dev/null 2>&1; then
            add_result "pass" "Docker Daemon" "Docker daemon running"
        else
            add_result "warn" "Docker Daemon" "Docker daemon not running"
        fi
    else
        add_result "warn" "Docker" "Docker not available (containerized builds disabled)"
    fi
    
    return 0
}

# Check AI tools integration
check_ai_tools() {
    local ai_tools=("rg" "jq" "yq")
    local available=()
    local missing=()
    
    for tool in "${ai_tools[@]}"; do
        if command_exists "$tool"; then
            available+=("$tool")
            add_result "pass" "AI Tool" "$tool available"
        else
            missing+=("$tool")
            add_result "warn" "AI Tool" "$tool missing"
        fi
    done
    
    # Check for Python tools
    if command_exists "python3"; then
        add_result "pass" "Python" "Python 3 available"
    else
        add_result "warn" "Python" "Python 3 missing"
    fi
    
    # Check tools directory
    if [[ -d "$TOOLS_DIR/ai" ]]; then
        local ai_scripts
        ai_scripts=$(find "$TOOLS_DIR/ai" -name "*.sh" -executable | wc -l)
        add_result "pass" "AI Scripts" "$ai_scripts AI tools available"
    else
        add_result "fail" "AI Scripts" "AI tools directory missing"
    fi
    
    return 0
}

# Platform-specific verification
run_platform_specific_checks() {
    local platform_script=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        platform_script="$SCRIPT_DIR/platforms/linux.sh"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        platform_script="$SCRIPT_DIR/platforms/macos.sh"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        platform_script="$SCRIPT_DIR/platforms/windows.sh"
    fi
    
    if [[ -n "$platform_script" && -x "$platform_script" ]]; then
        log_info "Running platform-specific checks..."
        if "$platform_script"; then
            add_result "pass" "Platform Check" "Platform-specific verification passed"
        else
            add_result "warn" "Platform Check" "Platform-specific verification had issues"
        fi
    else
        add_result "warn" "Platform Check" "No platform-specific checks available"
    fi
}

# Generate summary report
generate_summary() {
    local total_checks=$((${#PASSED_CHECKS[@]} + ${#FAILED_CHECKS[@]} + ${#WARNING_CHECKS[@]}))
    
    echo ""
    echo "================================================================================"
    echo "LIME-DEV SETUP VERIFICATION SUMMARY"
    echo "================================================================================"
    echo ""
    
    echo -e "${GREEN}PASSED CHECKS (${#PASSED_CHECKS[@]}):${NC}"
    for check in "${PASSED_CHECKS[@]}"; do
        echo "  ✅ $check"
    done
    echo ""
    
    if [[ ${#WARNING_CHECKS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}WARNINGS (${#WARNING_CHECKS[@]}):${NC}"
        for check in "${WARNING_CHECKS[@]}"; do
            echo "  ⚠️  $check"
        done
        echo ""
    fi
    
    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        echo -e "${RED}FAILED CHECKS (${#FAILED_CHECKS[@]}):${NC}"
        for check in "${FAILED_CHECKS[@]}"; do
            echo "  ❌ $check"
        done
        echo ""
    fi
    
    # Overall status
    local status_color="$GREEN"
    local status_text="READY"
    
    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        status_color="$RED"
        status_text="NEEDS SETUP"
    elif [[ ${#WARNING_CHECKS[@]} -gt 0 ]]; then
        status_color="$YELLOW"
        status_text="PARTIAL"
    fi
    
    echo "================================================================================"
    echo -e "OVERALL STATUS: ${status_color}${status_text}${NC}"
    echo "Total checks: $total_checks | Passed: ${#PASSED_CHECKS[@]} | Warnings: ${#WARNING_CHECKS[@]} | Failed: ${#FAILED_CHECKS[@]}"
    echo "================================================================================"
    
    # Return appropriate exit code
    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validates lime-dev development environment setup.

OPTIONS:
    --platform-only     Run only platform-specific checks
    --quick             Run only essential checks
    --verbose           Enable verbose output
    --help              Show this help message

EXAMPLES:
    $0                  # Complete verification
    $0 --quick          # Essential checks only
    $0 --platform-only  # Platform-specific only
    
EOF
}

# Main execution
main() {
    local platform_only=false
    local quick_mode=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --platform-only)
                platform_only=true
                shift
                ;;
            --quick)
                quick_mode=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "================================================================================"
    echo "LIME-DEV SETUP VERIFICATION"
    echo "================================================================================"
    echo ""
    
    # Run verification checks
    if [[ "$platform_only" == true ]]; then
        run_platform_specific_checks
    elif [[ "$quick_mode" == true ]]; then
        check_platform
        check_basic_requirements
        check_repository_structure
    else
        check_platform
        check_basic_requirements
        check_development_tools
        check_qemu_virtualization
        check_network_tools
        check_repository_structure
        check_managed_repos
        check_build_tools
        check_ai_tools
        run_platform_specific_checks
    fi
    
    # Generate and display summary
    generate_summary
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi