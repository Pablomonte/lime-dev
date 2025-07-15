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
    check           Check current setup status with dependency graph
    install         Full setup with user confirmation (safe)
    install-auto    Automated setup (use with caution)
    install-system  Install lime command system-wide via symlink
    update          Update repositories with dependency visualization
    deps            Check/install system dependencies
    graph           Show detailed dependency graph and configuration
    env             Show environment information
    
Options:
    --release       Use release mode (javierbrk repositories)
    --export-dot    Export dependency graph as DOT file (use with graph command)
    -h, --help      Show this help

Examples:
    $0 check                    # Check status with dependency graph
    $0 install                  # Safe interactive setup with graph
    $0 install --release        # Setup for release testing (javierbrk repos)
    $0 update                   # Update repositories with visualization
    $0 graph                    # Detailed dependency analysis
    $0 graph --export-dot       # Export professional graph file
    $0 deps                     # Check system dependencies

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
    local export_dot="false"
    
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
            graph)
                command="graph"
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
            --export-dot)
                export_dot="true"
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
            print_info "Running comprehensive environment check with dependency analysis..."
            echo ""
            "$SCRIPT_DIR/core/check-setup.sh"
            echo ""
            print_info "Repository Dependency Analysis:"
            "$SCRIPT_DIR/utils/dependency-graph.sh" ascii
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
            print_info "Updating repositories..."
            "$SCRIPT_DIR/utils/update-repos.sh"
            echo ""
            print_info "Repository Status After Update:"
            "$SCRIPT_DIR/utils/dependency-graph.sh" ascii
            ;;
        deps)
            "$SCRIPT_DIR/core/check-setup.sh" | grep -A 20 "System Dependencies"
            ;;
        graph)
            if [[ "$export_dot" == "true" ]]; then
                print_info "Exporting dependency graph as DOT file..."
                local dot_file="lime-dev-dependencies-$(date +%Y%m%d-%H%M%S).dot"
                "$SCRIPT_DIR/utils/dependency-graph.sh" dot "$dot_file"
                print_success "DOT file generated: $dot_file"
                echo ""
                print_info "Convert to image formats with:"
                echo "  dot -Tpng '$dot_file' -o dependency-graph.png"
                echo "  dot -Tsvg '$dot_file' -o dependency-graph.svg"
                echo "  dot -Tpdf '$dot_file' -o dependency-graph.pdf"
            else
                print_info "Comprehensive Dependency Analysis for LibreMesh Development Environment"
                echo ""
                print_info "=== Repository Dependency Visualization ==="
                "$SCRIPT_DIR/utils/dependency-graph.sh" ascii
                echo ""
                print_info "=== Configuration Summary ==="
                "$SCRIPT_DIR/utils/dependency-graph.sh" config
                echo ""
                print_info "=== Release Mode Comparison ==="
                if [[ "$release_mode" == "true" ]]; then
                    print_info "Currently in RELEASE MODE - showing release dependencies:"
                    "$SCRIPT_DIR/utils/dependency-graph.sh" release
                else
                    print_info "Currently in DEVELOPMENT MODE - release mode would use:"
                    "$SCRIPT_DIR/utils/dependency-graph.sh" release
                fi
                echo ""
                print_info "=== Graph Export Options ==="
                echo "Generate professional graphs with:"
                echo "  lime setup graph --export-dot    # Generate DOT file"
                echo "  dot -Tpng deps.dot -o graph.png  # Create PNG (requires graphviz)"
                echo "  dot -Tsvg deps.dot -o graph.svg  # Create SVG (requires graphviz)"
            fi
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