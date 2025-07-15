#!/usr/bin/env bash
#
# LibreRouterOS 24.10.1 Network Configuration
# Optimized for fresh builds with manual configuration
# Migrated from lime-app to lime-dev
#

setup_librerouteros_network() {
    print_status "Configuring LibreRouterOS 24.10.1 network (development configuration)..."
    
    # LibreRouterOS needs more time to boot
    print_status "Waiting for LibreRouterOS to fully initialize..."
    for i in {1..20}; do
        sudo screen -S libremesh -X hardcopy /tmp/boot_check.txt 2>/dev/null
        if grep -q "root@.*:/#\|OpenWrt.*#\|librerouteros.*#" /tmp/boot_check.txt 2>/dev/null; then
            print_status "✓ LibreRouterOS boot completed"
            break
        fi
        
        # Send Enter more frequently for LibreRouterOS
        if [ $((i % 2)) -eq 0 ]; then
            sudo screen -S libremesh -X stuff $'\n' 2>/dev/null || true
        fi
        
        sleep 2
        echo -n "."
    done
    echo
    
    print_status "Configuring LibreRouterOS network interfaces..."
    
    # LibreRouterOS-specific network setup
    sudo screen -S libremesh -X stuff 'echo "=== LibreRouterOS Network Discovery ==="; echo "Available interfaces:"; ip link show | grep -E "^[0-9]+:" | head -5'$'\n'
    sleep 3
    
    # Auto-detect and configure available network interfaces (LibreRouterOS)
    sudo screen -S libremesh -X stuff 'echo "=== LibreRouterOS Interface Auto-Detection ==="'$'\n'
    sleep 1
    
    # Show all available interfaces for debugging
    sudo screen -S libremesh -X stuff 'echo "Available interfaces:"; ip link show | grep -E "^[0-9]+:"'$'\n'
    sleep 2
    
    # Find the first non-loopback interface
    sudo screen -S libremesh -X stuff 'MAIN_IFC=$(ip link show | grep -E "^[0-9]+: " | grep -v "lo:" | head -1 | cut -d: -f2 | tr -d " "); echo "Main interface detected: $MAIN_IFC"'$'\n'
    sleep 2
    
    # Configure the main interface with IP
    sudo screen -S libremesh -X stuff 'if [ -n "$MAIN_IFC" ]; then echo "Configuring $MAIN_IFC with 10.13.0.1/16..."; ip link set $MAIN_IFC up; ip addr add 10.13.0.1/16 dev $MAIN_IFC 2>/dev/null || ip addr replace 10.13.0.1/16 dev $MAIN_IFC; echo "$MAIN_IFC configured"; else echo "No network interface found"; fi'$'\n'
    sleep 3
    
    # Configure eth0 directly (most reliable with virtio)
    sudo screen -S libremesh -X stuff 'if ip link show eth0 >/dev/null 2>&1; then echo "Configuring eth0..."; ip link set eth0 up; ip addr add 10.13.0.1/16 dev eth0 2>/dev/null || ip addr replace 10.13.0.1/16 dev eth0; echo "eth0 configured with 10.13.0.1/16"; else echo "eth0 not found"; fi'$'\n'
    sleep 3
    
    # Try to configure br-lan if available
    sudo screen -S libremesh -X stuff 'if ip link show br-lan >/dev/null 2>&1; then echo "br-lan found, configuring..."; ip addr add 10.13.0.1/16 dev br-lan 2>/dev/null || ip addr replace 10.13.0.1/16 dev br-lan; ip link set br-lan up; echo "br-lan configured"; else echo "br-lan not available (normal for LibreRouterOS)"; fi'$'\n'
    sleep 2
    
    # Verify IP configuration
    sudo screen -S libremesh -X stuff 'echo "=== LibreRouterOS IP Configuration ==="; ip addr show | grep -A1 "10.13.0.1"'$'\n'
    sleep 2
    
    # LibreRouterOS services configuration
    print_status "Configuring LibreRouterOS services..."
    
    # Set root password
    sudo screen -S libremesh -X stuff 'echo "Setting development password..."; echo -e "admin\\nadmin" | passwd root 2>/dev/null || echo "Password change may have failed"'$'\n'
    sleep 3
    
    # LibreRouterOS specific: Configure and start uHTTPd
    sudo screen -S libremesh -X stuff 'echo "Configuring uHTTPd for LibreRouterOS..."; if [ -f /etc/config/uhttpd ]; then echo "uHTTPd config found"; else echo "Creating basic uHTTPd config..."; mkdir -p /etc/config 2>/dev/null; fi'$'\n'
    sleep 2
    
    sudo screen -S libremesh -X stuff 'echo "Starting uHTTPd..."; /etc/init.d/uhttpd stop 2>/dev/null; /etc/init.d/uhttpd start || echo "uHTTPd start may have failed - will retry"'$'\n'
    sleep 3
    
    # Retry uHTTPd if needed
    sudo screen -S libremesh -X stuff 'if ! ps | grep -q "[u]httpd"; then echo "Retrying uHTTPd..."; uhttpd -f -p 80 -h /www -I index.html -x /cgi-bin -t 60 -T 10 -k 20 -K 5 -D &; sleep 1; echo "uHTTPd manual start attempted"; fi'$'\n'
    sleep 2
    
    # Start ubus
    sudo screen -S libremesh -X stuff 'echo "Starting ubus..."; /etc/init.d/ubus restart || ubusd &'$'\n'
    sleep 2
    
    # LibreRouterOS specific: Check for additional services
    sudo screen -S libremesh -X stuff 'echo "Checking LibreRouterOS specific services..."; if [ -f /etc/init.d/librerouter ]; then /etc/init.d/librerouter start; echo "LibreRouterOS service started"; else echo "No specific LibreRouterOS service found"; fi'$'\n'
    sleep 2
    
    # Verify network and create missing directories
    sudo screen -S libremesh -X stuff 'echo "Setting up web directories..."; mkdir -p /www/app 2>/dev/null; mkdir -p /www/cgi-bin 2>/dev/null; chmod 755 /www /www/app /www/cgi-bin 2>/dev/null; echo "Web directories ready"'$'\n'
    sleep 2
    
    # Final network verification
    print_status "Verifying LibreRouterOS network configuration..."
    sudo screen -S libremesh -X stuff 'echo "=== LibreRouterOS Network Status ==="; echo "IP Configuration:"; ip addr show | grep -A3 "10.13.0.1\|eth0\|br-lan" | head -8; echo "=== Interface Status ==="; ip link show | grep -E "(eth0|br-lan|UP)" | head -4; echo "=== Services Status ==="; echo "uHTTPd:"; ps | grep "[u]httpd" || echo "uHTTPd not running"; echo "ubus:"; ps | grep "[u]bus" || echo "ubus not running"; echo "=== Web Access ==="; echo "Primary: http://10.13.0.1/"; echo "lime-app: http://10.13.0.1/app/"; echo "Credentials: root/admin"; echo "=== Development Notes ==="; echo "- Fresh LibreRouterOS build"; echo "- Manual configuration applied"; echo "- Check /var/log/messages for issues"'$'\n'
    sleep 3
    
    print_status "LibreRouterOS 24.10.1 network configuration completed"
    print_status "✓ Fresh build: Ready for development"
    print_status "✓ Network: Manual configuration applied"
    print_status "✓ Web access: http://10.13.0.1/"
    print_status "✓ lime-app: http://10.13.0.1/app/"
    print_warning "Note: LibreRouterOS may need additional manual configuration"
    print_warning "Use 'sudo screen -r libremesh' to access console for debugging"
    
    # Clean up
    sudo rm -f /tmp/boot_check.txt 2>/dev/null || true
}