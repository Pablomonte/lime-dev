#!/bin/bash
#
# Lime-Dev System Installation Script
# Installs lime command system-wide for easy access from anywhere
#
# Usage:
#   ./install-system-lime.sh                    # Install to /usr/local/bin
#   ./install-system-lime.sh ~/.local/bin       # Install to user bin
#   sudo ./install-system-lime.sh               # System-wide installation
#

set -e

# Configuration
INSTALL_DIR="${1:-/usr/local/bin}"
LIME_DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_SCRIPT="$LIME_DEV_ROOT/scripts/lime"

print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1" >&2
}

echo "Lime-Dev System Installation"
echo "============================"
print_info "Install directory: $INSTALL_DIR"
print_info "Lime-dev root: $LIME_DEV_ROOT"
echo

# Validate lime script exists
if [[ ! -f "$LIME_SCRIPT" ]]; then
    print_error "lime script not found at $LIME_SCRIPT"
    exit 1
fi

# Validate install directory
if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "Install directory $INSTALL_DIR does not exist"
    print_info "Create it first: mkdir -p $INSTALL_DIR"
    exit 1
fi

if [[ ! -w "$INSTALL_DIR" ]]; then
    print_error "No write permission to $INSTALL_DIR"
    print_info "Try: sudo $0 $INSTALL_DIR"
    exit 1
fi

# Install lime script
print_info "Installing lime to $INSTALL_DIR/lime..."
cp "$LIME_SCRIPT" "$INSTALL_DIR/lime"
chmod +x "$INSTALL_DIR/lime"

print_success "Installation complete!"
echo
echo "Global lime command is now available:"
echo "  lime --help                     # Show help"
echo "  lime setup install              # Setup development environment" 
echo "  lime verify all                 # Verify installation"
echo "  lime ai review --repo lime-app  # AI code review"
echo "  lime build                      # Build firmware"
echo
print_info "The lime command references this lime-dev installation: $LIME_DEV_ROOT"
print_info "To uninstall: rm $INSTALL_DIR/lime"