#!/bin/bash
#
# LibreRouterOS Configuration Validator
# 
# This script validates LibreRouterOS repository configuration and ensures
# all required components are present for successful builds.
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
TARGET_REPO="${1}"
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
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

print_check() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to show usage
usage() {
    cat << EOF
LibreRouterOS Configuration Validator

Usage: $0 <target_repo_path>

Arguments:
    target_repo_path    Path to LibreRouterOS repository

Examples:
    $0 ../librerouteros
    $0 /path/to/librerouteros

EOF
}

# Function to validate repository structure
validate_repository() {
    print_header "Validating repository structure"
    
    local issues=0
    
    # Check basic OpenWrt structure
    if [ -f "$TARGET_REPO/Makefile" ]; then
        print_check "Makefile present"
    else
        print_fail "Makefile missing"
        issues=$((issues + 1))
    fi
    
    if [ -f "$TARGET_REPO/rules.mk" ]; then
        print_check "rules.mk present"
    else
        print_fail "rules.mk missing"
        issues=$((issues + 1))
    fi
    
    if [ -d "$TARGET_REPO/target" ]; then
        print_check "target/ directory present"
    else
        print_fail "target/ directory missing"
        issues=$((issues + 1))
    fi
    
    if [ -d "$TARGET_REPO/package" ]; then
        print_check "package/ directory present"
    else
        print_fail "package/ directory missing"
        issues=$((issues + 1))
    fi
    
    if [ -d "$TARGET_REPO/include" ]; then
        print_check "include/ directory present"
    else
        print_fail "include/ directory missing"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to validate essential scripts
validate_scripts() {
    print_header "Validating essential scripts"
    
    local issues=0
    
    # Check scripts directory
    if [ ! -d "$TARGET_REPO/scripts" ]; then
        print_fail "scripts/ directory missing"
        issues=$((issues + 1))
        return $issues
    fi
    
    # Check essential scripts
    local essential_scripts=(
        "feeds"
        "package-metadata.pl"
        "getver.sh"
        "get_source_date_epoch.sh"
        "config.guess"
        "download.pl"
        "kconfig.pl"
    )
    
    for script in "${essential_scripts[@]}"; do
        if [ -f "$TARGET_REPO/scripts/$script" ]; then
            print_check "scripts/$script present"
        else
            print_fail "scripts/$script missing"
            issues=$((issues + 1))
        fi
    done
    
    return $issues
}

# Function to validate feeds configuration
validate_feeds() {
    print_header "Validating feeds configuration"
    
    local issues=0
    
    # Check feeds.conf.default
    if [ -f "$TARGET_REPO/feeds.conf.default" ]; then
        print_check "feeds.conf.default present"
        
        # Check for LibreMesh feeds
        if grep -q "libremesh" "$TARGET_REPO/feeds.conf.default"; then
            print_check "LibreMesh feed configured"
        else
            print_warn "LibreMesh feed not configured"
            issues=$((issues + 1))
        fi
        
        # Check for routing feeds
        if grep -q "routing" "$TARGET_REPO/feeds.conf.default"; then
            print_check "Routing feed configured"
        else
            print_warn "Routing feed not configured"
        fi
        
    else
        print_fail "feeds.conf.default missing"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to validate build configurations
validate_configs() {
    print_header "Validating build configurations"
    
    local issues=0
    
    # Check configs directory
    if [ ! -d "$TARGET_REPO/configs" ]; then
        print_warn "configs/ directory missing"
        issues=$((issues + 1))
        return $issues
    fi
    
    # Check essential config files
    local config_files=(
        "default_config"
        "default_config_x86_64"
        "default_config_multi"
    )
    
    for config in "${config_files[@]}"; do
        if [ -f "$TARGET_REPO/configs/$config" ]; then
            print_check "configs/$config present"
        else
            print_warn "configs/$config missing"
            issues=$((issues + 1))
        fi
    done
    
    return $issues
}

# Function to validate LibreRouter specific components
validate_librerouteros() {
    print_header "Validating LibreRouterOS components"
    
    local issues=0
    
    # Check for LibreRouter hardware support
    if [ -f "$TARGET_REPO/target/linux/ath79/image/generic.mk" ]; then
        if grep -q "librerouter" "$TARGET_REPO/target/linux/ath79/image/generic.mk"; then
            print_check "LibreRouter hardware support present"
        else
            print_warn "LibreRouter hardware support may be missing"
            issues=$((issues + 1))
        fi
    else
        print_warn "ath79 generic.mk not found"
        issues=$((issues + 1))
    fi
    
    # Check for LibreMesh integration
    if [ -d "$TARGET_REPO/files" ]; then
        if [ -f "$TARGET_REPO/files/etc/config/lime-defaults" ]; then
            print_check "LibreMesh defaults present"
        else
            print_warn "LibreMesh defaults missing"
            issues=$((issues + 1))
        fi
    else
        print_warn "files/ directory missing"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Function to validate build environment
validate_build_environment() {
    print_header "Validating build environment"
    
    local issues=0
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_check "Docker available"
        
        if docker info &> /dev/null; then
            print_check "Docker daemon accessible"
        else
            print_fail "Docker daemon not accessible"
            issues=$((issues + 1))
        fi
    else
        print_fail "Docker not installed"
        issues=$((issues + 1))
    fi
    
    # Check disk space
    AVAILABLE_SPACE=$(df "$TARGET_REPO" | tail -1 | awk '{print $4}')
    REQUIRED_SPACE=20971520  # 20GB in KB
    
    if [ "$AVAILABLE_SPACE" -gt "$REQUIRED_SPACE" ]; then
        print_check "Sufficient disk space ($(($AVAILABLE_SPACE / 1024 / 1024))GB available)"
    else
        print_warn "Low disk space ($(($AVAILABLE_SPACE / 1024 / 1024))GB available, 20GB recommended)"
        issues=$((issues + 1))
    fi
    
    # Check memory
    if [ -f "/proc/meminfo" ]; then
        TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        REQUIRED_MEM=4194304  # 4GB in KB
        
        if [ "$TOTAL_MEM" -gt "$REQUIRED_MEM" ]; then
            print_check "Sufficient memory ($(($TOTAL_MEM / 1024 / 1024))GB available)"
        else
            print_warn "Low memory ($(($TOTAL_MEM / 1024 / 1024))GB available, 4GB recommended)"
            issues=$((issues + 1))
        fi
    fi
    
    return $issues
}

# Function to provide recommendations
provide_recommendations() {
    print_header "Recommendations"
    
    echo "Based on the validation, consider the following:"
    echo ""
    
    # Missing scripts recommendation
    if [ ! -f "$TARGET_REPO/scripts/feeds" ]; then
        print_info "Missing scripts can be copied from OpenWrt repository:"
        echo "  cp -r /path/to/openwrt/scripts/* $TARGET_REPO/scripts/"
    fi
    
    # Configuration recommendations
    if [ ! -d "$TARGET_REPO/configs" ]; then
        print_info "Create configs directory with target configurations:"
        echo "  mkdir -p $TARGET_REPO/configs"
        echo "  # Add default_config, default_config_x86_64, etc."
    fi
    
    # Build recommendations
    print_info "To build LibreRouterOS:"
    echo "  cd $SCRIPT_DIR"
    echo "  ./build-librerouteros.sh $TARGET_REPO x86_64"
    echo ""
    
    print_info "To monitor build progress:"
    echo "  ./monitor-build.sh start"
}

# Function to show validation summary
show_summary() {
    print_header "Validation Summary"
    
    local total_issues=$1
    
    if [ $total_issues -eq 0 ]; then
        print_info "✅ Repository validation passed!"
        print_info "Repository is ready for LibreRouterOS builds"
    elif [ $total_issues -le 5 ]; then
        print_warn "⚠️  Repository validation completed with warnings"
        print_info "Build may succeed but consider addressing warnings"
    else
        print_error "❌ Repository validation failed"
        print_info "Please address critical issues before building"
    fi
    
    echo ""
    print_info "Total issues found: $total_issues"
}

# Main execution
main() {
    print_header "LibreRouterOS Configuration Validator"
    
    # Handle help
    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ -z "$1" ]; then
        usage
        exit 0
    fi
    
    # Validate target repository
    if [ ! -d "$TARGET_REPO" ]; then
        print_error "Target repository not found: $TARGET_REPO"
        exit 1
    fi
    
    # Resolve absolute path
    TARGET_REPO=$(cd "$TARGET_REPO" && pwd)
    print_info "Validating repository: $TARGET_REPO"
    echo ""
    
    # Run validation checks
    local total_issues=0
    
    validate_repository
    total_issues=$((total_issues + $?))
    
    validate_scripts
    total_issues=$((total_issues + $?))
    
    validate_feeds
    total_issues=$((total_issues + $?))
    
    validate_configs
    total_issues=$((total_issues + $?))
    
    validate_librerouteros
    total_issues=$((total_issues + $?))
    
    validate_build_environment
    total_issues=$((total_issues + $?))
    
    echo ""
    
    # Provide recommendations
    provide_recommendations
    
    # Show summary
    show_summary $total_issues
    
    # Exit with appropriate code
    if [ $total_issues -gt 10 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"