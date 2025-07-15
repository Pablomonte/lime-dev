#!/usr/bin/env bash
#
# LibreMesh Build Environment Setup - Unified Script
# Single entry point for all setup operations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$SCRIPT_DIR")"

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

print_success() {
    echo "[SUCCESS] $1"
}

usage() {
    cat << EOF
LibreMesh Build Environment Setup

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check           Check current setup status (non-invasive)
    install         Full setup with user confirmation (safe)
    install-auto    Automated setup (use with caution)
    install-system  Install lime command system-wide via symlink
    update          Update repositories only
    deps            Check/install system dependencies
    env             Show environment information
    
Options:
    --release       Use release mode (javierbrk repositories)
    -h, --help      Show this help

Examples:
    $0 check                    # Check current status
    $0 install                  # Safe interactive setup
    $0 install --release        # Setup for release testing
    $0 update                   # Update repositories
    $0 deps                     # Check dependencies

Sub-scripts:
    ./check-setup.sh           # Direct status check
    ./setup-lime-dev-safe.sh   # Direct safe setup
    ./update-repos.sh          # Direct repo updates

EOF
}

check_directory() {
    local dir_name="$(basename "$PWD")"
    if [[ ! "$dir_name" =~ ^(lime-build|lime-dev)$ ]]; then
        print_error "This script should be run from the lime-dev (or lime-build) directory"
        exit 1
    fi
}

main() {
    local command="${1:-help}"
    local release_mode="false"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            check)
                command="check"
                shift
                ;;
            install)
                command="install"
                shift
                ;;
            install-auto)
                command="install-auto"
                shift
                ;;
            install-system)
                command="install-system"
                shift
                ;;
            update)
                command="update"
                shift
                ;;
            deps)
                command="deps"
                shift
                ;;
            env)
                command="env"
                shift
                ;;
            --release)
                release_mode="true"
                export LIME_RELEASE_MODE="true"
                shift
                ;;
            -h|--help|help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    check_directory
    
    print_info "LibreMesh Build Environment Setup"
    if [[ "$release_mode" == "true" ]]; then
        print_info "Release mode: ENABLED (using javierbrk repositories)"
    fi
    print_info ""
    
    case "$command" in
        check)
            exec "$SCRIPT_DIR/core/check-setup.sh"
            ;;
        install)
            exec "$SCRIPT_DIR/core/setup-lime-dev-safe.sh"
            ;;
        install-auto)
            print_info "Running automated setup (potentially disruptive)"
            exec "$SCRIPT_DIR/legacy/setup-lime-dev.sh"
            ;;
        install-system)
            print_info "Installing lime command system-wide..."
            local lime_script="$SCRIPT_DIR/lime"
            local system_lime="/usr/local/bin/lime"
            
            if [[ ! -f "$lime_script" ]]; then
                print_error "Local lime script not found: $lime_script"
                exit 1
            fi
            
            if [[ -L "$system_lime" ]]; then
                local current_target=$(readlink -f "$system_lime")
                local expected_target=$(readlink -f "$lime_script")
                
                if [[ "$current_target" == "$expected_target" ]]; then
                    print_success "System-wide lime already correctly linked"
                    exit 0
                else
                    print_info "Updating system-wide lime symlink..."
                    sudo rm "$system_lime"
                fi
            elif [[ -f "$system_lime" ]]; then
                print_info "Replacing existing system lime with symlink..."
                sudo rm "$system_lime"
            fi
            
            sudo ln -s "$lime_script" "$system_lime"
            print_success "Installed lime system-wide via symlink"
            print_info "You can now run 'lime' from anywhere"
            ;;
        update)
            exec "$SCRIPT_DIR/utils/update-repos.sh"
            ;;
        deps)
            "$SCRIPT_DIR/core/check-setup.sh" | grep -A 20 "System Dependencies"
            ;;
        env)
            source "$SCRIPT_DIR/utils/env-setup.sh"
            "$SCRIPT_DIR/utils/env-setup.sh" show
            ;;
        help)
            usage
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"