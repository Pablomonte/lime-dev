#!/bin/bash
# Test script to simulate fresh developer experience
set -e

echo "=== lime-dev Fresh Clone Test ==="
echo "This script simulates a new developer cloning and setting up lime-dev"
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test directory
TEST_DIR="/tmp/lime-dev-test-$(date +%s)"
RESULTS_FILE="$TEST_DIR/test-results.log"

echo -e "${YELLOW}Creating test directory: $TEST_DIR${NC}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Function to log results
log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

# Clone repository
echo -e "\n${YELLOW}Step 1: Cloning repository...${NC}"
if git clone https://github.com/Fede654/lime-dev.git; then
    log_result "✓ Repository clone successful"
else
    log_result "✗ Repository clone failed"
    exit 1
fi

cd lime-dev

# Check repository structure
echo -e "\n${YELLOW}Step 2: Verifying repository structure...${NC}"
REQUIRED_FILES=("lime" "scripts/setup.sh" "scripts/lime" "configs/versions.conf" "README.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_result "✓ Found: $file"
    else
        log_result "✗ Missing: $file"
    fi
done

# Test/Create lime symlink
echo -e "\n${YELLOW}Step 3: Testing lime command access...${NC}"
if [ ! -f "lime" ]; then
    log_result "! Creating missing lime symlink"
    ln -s scripts/lime lime
fi

if ./lime --help &>/dev/null; then
    log_result "✓ lime command accessible"
else
    log_result "✗ lime command not working"
fi

# Run setup script (check mode)
echo -e "\n${YELLOW}Step 4: Running setup check...${NC}"
if ./lime setup check; then
    log_result "✓ Setup check completed successfully"
else
    log_result "✗ Setup check failed"
fi

# Verify setup
echo -e "\n${YELLOW}Step 5: Basic environment verification...${NC}"
if ./lime verify platform; then
    log_result "✓ Platform verification passed"
else
    log_result "✗ Platform verification failed"
fi

# Check cloned repositories
echo -e "\n${YELLOW}Step 6: Checking managed repositories...${NC}"
REPOS=("lime-app" "lime-packages" "librerouteros" "kconfig-utils")
for repo in "${REPOS[@]}"; do
    if [ -d "repos/$repo" ]; then
        log_result "✓ Repository exists: $repo"
        # Check if it's the R2 fork for librerouteros
        if [ "$repo" = "librerouteros" ]; then
            cd "repos/$repo"
            REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "none")
            if [[ "$REMOTE_URL" == *"javierbrk"* ]]; then
                log_result "✓ LibreRouterOS using R2 support fork"
            else
                log_result "! LibreRouterOS not using R2 fork: $REMOTE_URL"
            fi
            cd ../..
        fi
    else
        log_result "✗ Repository missing: $repo"
    fi
done

# Test AI tools dependencies
echo -e "\n${YELLOW}Step 7: Testing AI tools dependencies...${NC}"
if ./tools/ai/install-dependencies.sh &>/dev/null; then
    log_result "✓ AI dependencies installed successfully"
else
    log_result "✗ AI dependencies installation failed"
fi

# Test build command (dry run)
echo -e "\n${YELLOW}Step 8: Testing build system...${NC}"
if ./lime build --help &>/dev/null; then
    log_result "✓ Build system accessible"
else
    log_result "✗ Build system not working"
fi

# Summary
echo -e "\n${GREEN}=== Test Summary ===${NC}"
echo "Test directory: $TEST_DIR"
echo "Results saved to: $RESULTS_FILE"
echo
cat "$RESULTS_FILE"

echo -e "\n${YELLOW}To clean up test directory:${NC}"
echo "rm -rf $TEST_DIR"

echo -e "\n${YELLOW}To enter test environment:${NC}"
echo "cd $TEST_DIR/lime-dev"
echo
echo -e "${YELLOW}Quick commands to try:${NC}"
echo "./lime setup check      # Check setup status"
echo "./lime verify all       # Verify environment"
echo "./lime build            # Build firmware"