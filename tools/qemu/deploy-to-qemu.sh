#!/usr/bin/env bash
#
# Official LibreMesh lime-app development integration script
# Migrated from lime-app to lime-dev
# 
# This script follows the official workflow documented in:
# - lime-packages/TESTING.md (line 241)
# - lime-packages/packages/lime-app/Makefile (lines 39-40)
#
# Usage: ./deploy-to-qemu.sh [--build-only] [--start-qemu] [--project PROJECT]
#

set -e

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration (lime-dev structure)
LIME_PACKAGES_DIR="${LIME_PACKAGES_DIR:-$SCRIPT_DIR/../../repos/lime-packages}"
PROJECT_NAME="${1:-lime-app}"  # Default to lime-app, can be overridden
PROJECT_DIR="$SCRIPT_DIR/../../repos/$PROJECT_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Auto-detect project type and configuration
detect_project_config() {
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Project directory not found: $PROJECT_DIR"
        print_error "Available projects in repos/:"
        ls -d "$SCRIPT_DIR/../../repos"/* 2>/dev/null | xargs -I {} basename {} || echo "  None found"
        exit 1
    fi
    
    # Detect project type and set deployment target
    if [ -f "$PROJECT_DIR/package.json" ]; then
        PROJECT_TYPE="npm"
        DEPLOYMENT_TARGET="$LIME_PACKAGES_DIR/packages/$PROJECT_NAME/files/www/app"
        BUILD_COMMAND="npm run build:production || npm run build"
        BUILD_DIR="$PROJECT_DIR/build"
    elif [ -f "$PROJECT_DIR/Makefile" ]; then
        PROJECT_TYPE="makefile"
        DEPLOYMENT_TARGET="$LIME_PACKAGES_DIR/packages/$PROJECT_NAME/files"
        BUILD_COMMAND="make"
        BUILD_DIR="$PROJECT_DIR/dist"
    else
        print_error "Unknown project type in $PROJECT_DIR"
        print_error "Supported: package.json (npm) or Makefile"
        exit 1
    fi
    
    print_status "Detected project: $PROJECT_NAME ($PROJECT_TYPE)"
    print_status "Deployment target: $DEPLOYMENT_TARGET"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if [ ! -d "$LIME_PACKAGES_DIR" ]; then
        print_error "lime-packages directory not found at $LIME_PACKAGES_DIR"
        print_error "Please ensure lime-packages is available in repos/"
        exit 1
    fi
    
    # Check for QEMU images (will delegate to qemu-manager for detection)
    if [ ! -d "$LIME_PACKAGES_DIR/build" ]; then
        print_warning "No build directory found in lime-packages"
        print_warning "QEMU images may not be available"
    fi
    
    print_status "Prerequisites check passed"
}

# Build project
build_project() {
    print_status "Building $PROJECT_NAME..."
    
    cd "$PROJECT_DIR"
    
    if [ "$PROJECT_TYPE" = "npm" ]; then
        # Check if build:production exists, fallback to build
        if npm run | grep -q "build:production"; then
            npm run build:production
        else
            npm run build
        fi
    elif [ "$PROJECT_TYPE" = "makefile" ]; then
        make clean || true
        make
    fi
    
    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory not found at $BUILD_DIR. Build failed?"
        exit 1
    fi
    
    print_status "$PROJECT_NAME build completed"
}

# Deploy to lime-packages (official method)
deploy_to_lime_packages() {
    print_status "Deploying $PROJECT_NAME to lime-packages (official method)..."
    
    # Create the deployment directory
    mkdir -p "$DEPLOYMENT_TARGET"
    
    # Clean old build files to prevent accumulation
    print_warning "Cleaning old build files..."
    rm -rf "$DEPLOYMENT_TARGET"/*
    
    # Copy build files (official LibreMesh workflow)
    cp -r "$BUILD_DIR"/* "$DEPLOYMENT_TARGET/"
    
    print_status "$PROJECT_NAME deployed to $DEPLOYMENT_TARGET"
    print_status "Files deployed:"
    ls -la "$DEPLOYMENT_TARGET" | head -10
}

# Start QEMU with project integration
start_qemu() {
    print_status "Starting QEMU LibreMesh with $PROJECT_NAME integration..."
    
    # Use the qemu-manager from lime-dev
    "$SCRIPT_DIR/qemu-manager.sh" start
}

# Parse command line arguments
BUILD_ONLY=false
START_QEMU=false
PROJECT_OVERRIDE=""

for arg in "$@"; do
    case $arg in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --start-qemu)
            START_QEMU=true
            shift
            ;;
        --project)
            PROJECT_OVERRIDE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--build-only] [--start-qemu] [--project PROJECT]"
            echo ""
            echo "Options:"
            echo "  --build-only    Only build and deploy project, don't start QEMU"
            echo "  --start-qemu    Also start QEMU after building and deploying"
            echo "  --project NAME  Deploy specific project (default: lime-app)"
            echo "  --help          Show this help message"
            echo ""
            echo "Default behavior: Build and deploy project only"
            echo ""
            echo "Examples:"
            echo "  $0                         # Build and deploy lime-app only"
            echo "  $0 --start-qemu            # Build, deploy lime-app, and start QEMU"
            echo "  $0 --project lime-packages # Deploy lime-packages project"
            exit 0
            ;;
        *)
            # Handle positional argument for project name
            if [ -z "$PROJECT_OVERRIDE" ]; then
                PROJECT_OVERRIDE="$arg"
            else
                print_error "Unknown option: $arg"
                print_error "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

# Override project name if specified
if [ -n "$PROJECT_OVERRIDE" ]; then
    PROJECT_NAME="$PROJECT_OVERRIDE"
    PROJECT_DIR="$SCRIPT_DIR/../../repos/$PROJECT_NAME"
fi

# Main execution
print_status "=== LibreMesh $PROJECT_NAME Development Integration ==="
print_status "Following official LibreMesh development workflow"

detect_project_config
check_prerequisites
build_project
deploy_to_lime_packages

if [ "$START_QEMU" = true ]; then
    start_qemu
else
    print_status "=== Deployment Complete ==="
    print_status "$PROJECT_NAME has been deployed to lime-packages"
    print_status ""
    print_status "To start QEMU LibreMesh:"
    print_status "  $0 --start-qemu"
    print_status ""
    print_status "Or use qemu-manager:"
    print_status "  $SCRIPT_DIR/qemu-manager.sh start"
fi