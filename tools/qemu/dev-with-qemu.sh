#!/usr/bin/env bash
#
# LibreMesh project development with QEMU integration
# Migrated from lime-app to lime-dev
# 
# This script sets up a complete development environment with:
# - Project development server pointing to QEMU LibreMesh
# - Automatic rebuilding and redeployment
# - Network configuration for seamless integration
#

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_action() {
    echo -e "${BLUE}[ACTION]${NC} $1"
}

# Configuration
QEMU_IP="10.13.0.1"
DEV_SERVER_PORT="8080"
PROJECT_NAME="${PROJECT_NAME:-lime-app}"
PROJECT_DIR="$SCRIPT_DIR/../../repos/$PROJECT_NAME"

print_header() {
    echo -e "${GREEN}"
    echo "======================================"
    echo "  LibreMesh + $PROJECT_NAME Development"
    echo "======================================"
    echo -e "${NC}"
}

check_qemu_running() {
    print_status "Checking if QEMU LibreMesh is running..."
    
    if ping -c 1 -W 1 "$QEMU_IP" >/dev/null 2>&1; then
        print_status "✓ QEMU LibreMesh is running at $QEMU_IP"
        return 0
    else
        print_warning "✗ QEMU LibreMesh not reachable at $QEMU_IP"
        return 1
    fi
}

check_qemu_services() {
    print_status "Checking LibreMesh services..."
    
    # Check if ubus is accessible
    if curl -s --connect-timeout 2 "http://$QEMU_IP/ubus" >/dev/null 2>&1; then
        print_status "✓ ubus service is accessible"
    else
        print_warning "✗ ubus service not accessible"
    fi
    
    # Check if project is deployed
    if curl -s --connect-timeout 2 "http://$QEMU_IP/app/" | grep -q "LimeApp\|LibreMesh" 2>/dev/null; then
        print_status "✓ $PROJECT_NAME is deployed and accessible"
    else
        print_warning "✗ $PROJECT_NAME not found at http://$QEMU_IP/app/"
        print_warning "  Run: $SCRIPT_DIR/deploy-to-qemu.sh to deploy $PROJECT_NAME"
    fi
}

check_project_exists() {
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory not found: $PROJECT_DIR"
        print_error "Available projects in repos/:"
        ls -d "$SCRIPT_DIR/../../repos"/* 2>/dev/null | xargs -I {} basename {} || echo "  None found"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_DIR/package.json" ]; then
        print_error "Not an npm project: $PROJECT_DIR"
        print_error "Development server requires package.json"
        exit 1
    fi
}

start_development_server() {
    print_status "Starting $PROJECT_NAME development server..."
    print_status "Backend: QEMU LibreMesh at $QEMU_IP"
    print_status "Frontend: Development server at http://localhost:$DEV_SERVER_PORT"
    
    check_project_exists
    
    cd "$PROJECT_DIR"
    
    print_action "Starting development server with QEMU backend..."
    print_warning "Use Ctrl+C to stop the development server"
    
    # Set NODE_HOST to point to QEMU and start dev server
    env NODE_HOST="$QEMU_IP" npm run dev
}

show_usage() {
    echo "Usage: $0 [COMMAND] [PROJECT]"
    echo ""
    echo "Commands:"
    echo "  check       Check QEMU LibreMesh status and services"
    echo "  dev         Start development server connected to QEMU"
    echo "  deploy      Build and deploy project to QEMU"
    echo "  full        Deploy and start development server"
    echo "  help        Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_NAME - Override project name (default: lime-app)"
    echo ""
    echo "Examples:"
    echo "  $0 check                    # Check if QEMU is running and services are accessible"
    echo "  $0 deploy                   # Build and deploy $PROJECT_NAME to QEMU"
    echo "  $0 dev                      # Start development server pointing to QEMU"
    echo "  $0 full                     # Deploy and start development server"
    echo "  PROJECT_NAME=lime-packages $0 dev  # Use different project"
}

show_development_info() {
    echo ""
    print_status "=== Development Environment Ready ==="
    print_status ""
    print_status "🌐 QEMU LibreMesh:     http://$QEMU_IP"
    print_status "🚀 $PROJECT_NAME (prod):    http://$QEMU_IP/app"
    print_status "⚡ $PROJECT_NAME (dev):     http://localhost:$DEV_SERVER_PORT"
    print_status ""
    print_status "Development Workflow:"
    print_status "1. Edit code in your favorite editor"
    print_status "2. Changes auto-reload in development server"
    print_status "3. Test against real LibreMesh backend"
    print_status "4. Deploy with: $SCRIPT_DIR/deploy-to-qemu.sh"
    print_status ""
}

# Handle PROJECT_NAME override from command line
if [ "$#" -ge 2 ]; then
    PROJECT_NAME="$2"
    PROJECT_DIR="$SCRIPT_DIR/../../repos/$PROJECT_NAME"
fi

# Parse command
COMMAND="${1:-help}"

case "$COMMAND" in
    "check")
        print_header
        if check_qemu_running; then
            check_qemu_services
        else
            print_error "QEMU LibreMesh is not running"
            print_action "Start QEMU with: $SCRIPT_DIR/qemu-manager.sh start"
            exit 1
        fi
        ;;
    
    "dev")
        print_header
        if ! check_qemu_running; then
            print_error "QEMU LibreMesh is not running"
            print_action "Start QEMU with: $SCRIPT_DIR/qemu-manager.sh start"
            exit 1
        fi
        
        show_development_info
        start_development_server
        ;;
    
    "deploy")
        print_header
        print_action "Building and deploying $PROJECT_NAME to QEMU..."
        "$SCRIPT_DIR/deploy-to-qemu.sh" --build-only --project "$PROJECT_NAME"
        print_status "Deployment complete!"
        ;;
    
    "full")
        print_header
        print_action "Deploying $PROJECT_NAME and starting development server..."
        "$SCRIPT_DIR/deploy-to-qemu.sh" --build-only --project "$PROJECT_NAME"
        
        if ! check_qemu_running; then
            print_error "QEMU LibreMesh is not running"
            print_action "Start QEMU with: $SCRIPT_DIR/qemu-manager.sh start"
            exit 1
        fi
        
        show_development_info
        start_development_server
        ;;
    
    "help"|"--help"|*)
        show_usage
        ;;
esac