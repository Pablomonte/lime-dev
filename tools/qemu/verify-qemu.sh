#!/bin/bash

# QEMU LibreMesh Environment Verification Script
# Verifies QEMU LibreMesh setup and connectivity

set -e

echo "🖥️  QEMU LibreMesh Environment Verification"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
QEMU_IP="10.13.0.1"
HOST_IP="10.13.0.2"
TIMEOUT=5

# Helper functions
success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if QEMU process is running
echo -e "\n${BLUE}QEMU Process Check${NC}"
echo "------------------"

if pgrep -f "qemu-system-x86_64" >/dev/null; then
    success "QEMU process is running"
    
    # Show QEMU process details
    QEMU_PID=$(pgrep -f "qemu-system-x86_64")
    info "QEMU PID: $QEMU_PID"
    
    # Check if screen session exists
    if screen -list | grep -q "libremesh"; then
        success "LibreMesh screen session found"
        info "Access with: screen -r libremesh"
    else
        warning "LibreMesh screen session not found"
        info "QEMU may have been started without screen"
    fi
else
    error "QEMU process not running"
    echo "Start with: npm run qemu:start"
    exit 1
fi

# Check network connectivity
echo -e "\n${BLUE}Network Connectivity${NC}"
echo "--------------------"

# Check if we can ping the QEMU LibreMesh
if ping -c 1 -W $TIMEOUT $QEMU_IP >/dev/null 2>&1; then
    success "QEMU LibreMesh reachable at $QEMU_IP"
else
    error "Cannot reach QEMU LibreMesh at $QEMU_IP"
    warning "Network bridge may not be configured properly"
    
    # Check if bridge interface exists
    if ip link show | grep -q "br-"; then
        info "Bridge interface found"
    else
        warning "Bridge interface not found"
    fi
    exit 1
fi

# Check LibreMesh web interface
echo -e "\n${BLUE}LibreMesh Web Interface${NC}"
echo "-----------------------"

if curl -s --connect-timeout $TIMEOUT http://$QEMU_IP >/dev/null; then
    success "LibreMesh web interface accessible"
    
    # Test ubus endpoint (key for lime-app development)
    if curl -s --connect-timeout $TIMEOUT http://$QEMU_IP/ubus >/dev/null; then
        success "ubus endpoint accessible"
    else
        warning "ubus endpoint not accessible - may affect API development"
    fi
    
    # Test lime-app endpoint
    if curl -s --connect-timeout $TIMEOUT http://$QEMU_IP/app >/dev/null; then
        success "lime-app accessible at http://$QEMU_IP/app"
    else
        warning "lime-app not found - run 'npm run qemu:deploy' to deploy"
    fi
    
else
    error "LibreMesh web interface not accessible"
    warning "uhttpd web server may not be running in QEMU"
    exit 1
fi

# Check LibreMesh system status
echo -e "\n${BLUE}LibreMesh System Status${NC}"
echo "-----------------------"

# Test basic ubus call to check system health
if command -v curl >/dev/null 2>&1; then
    # Try to get system info via ubus
    UBUS_RESPONSE=$(curl -s --connect-timeout $TIMEOUT \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"call","params":["00000000000000000000000000000000","system","info",{}]}' \
        http://$QEMU_IP/ubus 2>/dev/null || echo "")
    
    if [ -n "$UBUS_RESPONSE" ] && echo "$UBUS_RESPONSE" | grep -q '"result"'; then
        success "ubus system calls working"
        
        # Extract system info if possible
        if echo "$UBUS_RESPONSE" | grep -q '"uptime"'; then
            info "LibreMesh system is responding to API calls"
        fi
    else
        warning "ubus system calls not responding properly"
        info "This may affect lime-app functionality"
    fi
fi

# Check required files and directories
echo -e "\n${BLUE}Development Environment${NC}"
echo "-----------------------"

# Check if lime-packages directory exists
if [ -d "../lime-packages" ]; then
    success "lime-packages repository found"
    
    # Check QEMU development script
    if [ -x "../lime-packages/tools/qemu_dev_start" ]; then
        success "QEMU development script available"
    else
        warning "QEMU development script not executable"
    fi
    
    # Check for LibreMesh images
    if [ -d "../lime-packages/build" ]; then
        IMAGE_COUNT=$(find ../lime-packages/build -name "*.tar.gz" -o -name "*.img.gz" | wc -l)
        if [ "$IMAGE_COUNT" -gt 0 ]; then
            success "LibreMesh images found ($IMAGE_COUNT files)"
        else
            warning "No LibreMesh images found in build directory"
        fi
    else
        warning "build directory not found in lime-packages"
    fi
else
    error "lime-packages repository not found"
    echo "Clone with: git clone https://github.com/libremesh/lime-packages.git ../lime-packages"
fi

# Check development server compatibility
echo -e "\n${BLUE}Development Integration${NC}"
echo "-----------------------"

# Check if development server can proxy to QEMU
if [ -f "preact.config.js" ]; then
    if grep -q "10.13.0.1" preact.config.js; then
        success "Development server configured to proxy to QEMU"
    else
        warning "Development server proxy configuration may need updating"
    fi
else
    warning "preact.config.js not found - proxy configuration unknown"
fi

# Test development workflow
if ping -c 1 -W $TIMEOUT $QEMU_IP >/dev/null 2>&1; then
    info "Ready for development with: npm run qemu:dev"
    info "Access development server at: http://localhost:8080"
    info "Access QEMU LibreMesh at: http://$QEMU_IP"
fi

# Performance check
echo -e "\n${BLUE}Performance Check${NC}"
echo "-----------------"

# Measure response time
if command -v curl >/dev/null 2>&1; then
    RESPONSE_TIME=$(curl -s -w "%{time_total}" --connect-timeout $TIMEOUT http://$QEMU_IP -o /dev/null)
    
    if [ -n "$RESPONSE_TIME" ]; then
        # Convert to milliseconds for readability
        RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc -l 2>/dev/null || echo "N/A")
        if [ "$RESPONSE_MS" != "N/A" ]; then
            success "Response time: ${RESPONSE_MS}ms"
            
            # Warn if response time is high
            if (( $(echo "$RESPONSE_TIME > 1.0" | bc -l 2>/dev/null || echo 0) )); then
                warning "Response time is high - may indicate performance issues"
            fi
        fi
    fi
fi

# Check available resources
if command -v free >/dev/null 2>&1; then
    MEMORY_INFO=$(free -h | grep "Mem:")
    info "Host memory: $MEMORY_INFO"
fi

# Summary and recommendations
echo -e "\n${BLUE}Verification Summary${NC}"
echo "===================="

# Count checks based on previous outputs
if pgrep -f "qemu-system-x86_64" >/dev/null && \
   ping -c 1 -W $TIMEOUT $QEMU_IP >/dev/null 2>&1 && \
   curl -s --connect-timeout $TIMEOUT http://$QEMU_IP >/dev/null; then
    
    echo -e "${GREEN}🎉 QEMU LibreMesh environment is ready!${NC}"
    echo
    echo "Next steps:"
    echo "  • Start development server: npm run qemu:dev"
    echo "  • Access development at: http://localhost:8080"
    echo "  • Access LibreMesh at: http://$QEMU_IP"
    echo "  • Deploy changes with: npm run qemu:deploy"
    echo "  • Access QEMU console: screen -r libremesh"
    
    exit 0
else
    echo -e "${RED}❌ QEMU LibreMesh environment has issues${NC}"
    echo
    echo "Troubleshooting:"
    echo "  • Restart QEMU: npm run qemu:start"
    echo "  • Check setup guide: DEVELOPMENT_SETUP.md"
    echo "  • Verify network: ping $QEMU_IP"
    echo "  • Check console: screen -r libremesh"
    
    exit 1
fi