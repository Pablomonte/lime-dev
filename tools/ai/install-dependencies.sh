#!/bin/bash

# AI Tools Dependencies Installer
# Installs required tools for AI-powered development analysis

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    echo "Installing AI Tools Dependencies"
    echo "================================"
    
    # Check current status
    if check_ai_tools; then
        log_success "All required tools are already installed"
        exit 0
    fi
    
    # Install dependencies
    if install_ai_dependencies; then
        echo ""
        log_success "Dependencies installed successfully"
        
        # Verify installation
        if check_ai_tools; then
            log_success "All tools are now working correctly"
        else
            log_warning "Some tools may not be working correctly. Please check manually."
        fi
    else
        log_error "Failed to install dependencies"
        exit 1
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi