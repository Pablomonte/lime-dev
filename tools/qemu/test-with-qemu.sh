#!/bin/bash

# Test script for running lime-app tests with QEMU LibreMesh backend
set -e

echo "🧪 LiMeApp Testing with QEMU LibreMesh Integration"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if QEMU is available
check_qemu() {
    print_status "Checking QEMU LibreMesh availability..."
    
    if curl -s --connect-timeout 5 "http://10.13.0.1/ubus" > /dev/null; then
        print_success "QEMU LibreMesh is running at 10.13.0.1"
        return 0
    else
        print_error "QEMU LibreMesh is not available at 10.13.0.1"
        return 1
    fi
}

# Run tests with different configurations
run_tests() {
    local test_type=$1
    local test_pattern=$2
    
    print_status "Running $test_type tests..."
    
    case $test_type in
        "unit")
            npm test -- --testPathIgnorePatterns="integration.spec" --coverage
            ;;
        "integration")
            if check_qemu; then
                print_status "Running integration tests with QEMU backend..."
                QEMU_TEST=true npm test -- --testPathPattern="integration.spec"
            else
                print_warning "Skipping integration tests - QEMU not available"
                npm test -- --testPathPattern="integration.spec"
            fi
            ;;
        "all")
            npm test -- --coverage
            ;;
        "pattern")
            npm test -- --testPathPattern="$test_pattern"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            exit 1
            ;;
    esac
}

# Lint and format check
check_quality() {
    print_status "Running quality checks..."
    
    print_status "TypeScript compilation..."
    npm run tsc 2>/dev/null || {
        print_error "TypeScript compilation failed"
        return 1
    }
    
    print_status "ESLint check..."
    npm run lint 2>/dev/null || {
        print_warning "ESLint issues found - continuing..."
    }
    
    print_success "Quality checks completed"
}

# Setup test environment
setup_test_env() {
    print_status "Setting up test environment..."
    
    # Ensure dependencies are installed
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    
    # Clear Jest cache
    npm run clear-jest 2>/dev/null || true
    
    print_success "Test environment ready"
}

# Deploy latest changes to QEMU if available
deploy_to_qemu() {
    if check_qemu; then
        print_status "Deploying latest changes to QEMU..."
        npm run qemu:deploy 2>/dev/null || {
            print_warning "Failed to deploy to QEMU - continuing with tests"
        }
    fi
}

# Main execution
main() {
    local test_type=${1:-"all"}
    local test_pattern=${2:-""}
    
    echo "Starting test suite with type: $test_type"
    echo
    
    # Setup
    setup_test_env
    
    # Deploy to QEMU if available
    deploy_to_qemu
    
    # Run quality checks
    check_quality
    
    # Run tests
    run_tests "$test_type" "$test_pattern"
    
    echo
    print_success "Test suite completed!"
    
    # Show coverage if available
    if [ -f "coverage/lcov-report/index.html" ]; then
        print_status "Coverage report available at: coverage/lcov-report/index.html"
    fi
}

# Help message
show_help() {
    echo "Usage: $0 [TEST_TYPE] [PATTERN]"
    echo
    echo "TEST_TYPE:"
    echo "  unit        - Run unit tests only (no integration)"
    echo "  integration - Run integration tests (with QEMU if available)"
    echo "  all         - Run all tests (default)"
    echo "  pattern     - Run tests matching pattern"
    echo
    echo "PATTERN:"
    echo "  Test file pattern to match (used with 'pattern' type)"
    echo
    echo "Examples:"
    echo "  $0 unit                    # Run unit tests only"
    echo "  $0 integration            # Run integration tests"
    echo "  $0 pattern remotesupport  # Run tests matching 'remotesupport'"
    echo
    echo "Environment variables:"
    echo "  QEMU_TEST=true            # Enable QEMU integration tests"
    echo
    echo "Prerequisites:"
    echo "  - npm install completed"
    echo "  - QEMU LibreMesh running at 10.13.0.1 (for integration tests)"
    echo
}

# Handle command line arguments
case "${1:-}" in
    "-h"|"--help"|"help")
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac