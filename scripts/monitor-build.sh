#!/bin/bash
#
# LibreRouterOS Build Monitor
# Monitors the build progress and provides real-time status
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} ✅ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} ❌ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} ⚠️ $1"
}

monitor_docker_build() {
    print_status "Starting LibreRouterOS build monitoring..."
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        return 1
    fi
    
    # Monitor loop
    local start_time=$(date +%s)
    local last_check=0
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local elapsed_min=$((elapsed / 60))
        local elapsed_sec=$((elapsed % 60))
        
        # Check for running containers
        local containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v NAMES)
        
        if [ -z "$containers" ]; then
            print_status "No containers currently running"
            
            # Check for completed containers
            local completed=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep "Exited")
            if [ ! -z "$completed" ]; then
                print_status "Recent container activity:"
                echo "$completed"
            fi
            
            # Check for build artifacts
            if [ -d "bin/targets" ]; then
                local images=$(find bin/targets -name "*.bin" -o -name "*.img.gz" 2>/dev/null)
                if [ ! -z "$images" ]; then
                    print_success "Build artifacts found:"
                    echo "$images"
                    return 0
                fi
            fi
            
            sleep 10
        else
            print_status "Active containers (${elapsed_min}m ${elapsed_sec}s elapsed):"
            echo "$containers"
            
            # Show resource usage
            local mem_usage=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -v NAME)
            if [ ! -z "$mem_usage" ]; then
                print_status "Resource usage:"
                echo "$mem_usage"
            fi
            
            # Check for build logs every 30 seconds
            if [ $((elapsed - last_check)) -ge 30 ]; then
                check_build_progress
                last_check=$elapsed
            fi
            
            sleep 5
        fi
        
        # Safety timeout after 2 hours
        if [ $elapsed -gt 7200 ]; then
            print_warning "Build has been running for over 2 hours, stopping monitor"
            return 1
        fi
    done
}

check_build_progress() {
    # Try to get logs from the most recent container
    local container_id=$(docker ps -q | head -1)
    if [ ! -z "$container_id" ]; then
        local recent_logs=$(docker logs --tail 5 $container_id 2>/dev/null | grep -E "(INFO|ERROR|Building|Compiling|Installing)")
        if [ ! -z "$recent_logs" ]; then
            print_status "Recent build activity:"
            echo "$recent_logs" | sed 's/^/  /'
        fi
    fi
    
    # Check for common build phases
    if [ -f "docker-build.log" ]; then
        local phase=$(tail -20 docker-build.log | grep -E "(Checking|Updating|Installing|Configuring|Building|Starting)" | tail -1)
        if [ ! -z "$phase" ]; then
            print_status "Current phase: $(echo $phase | sed 's/\[.*\]//' | sed 's/^[[:space:]]*//')"
        fi
        
        # Check for errors
        local errors=$(tail -20 docker-build.log | grep -E "(Error|ERROR|Failed|FAILED)" | wc -l)
        if [ $errors -gt 0 ]; then
            print_warning "Detected $errors recent error(s)"
        fi
    fi
}

# Main execution
if [ "$1" = "start" ]; then
    monitor_docker_build
elif [ "$1" = "logs" ]; then
    if [ -f "docker-build.log" ]; then
        tail -f docker-build.log
    else
        print_error "No build log found"
    fi
elif [ "$1" = "status" ]; then
    check_build_progress
else
    echo "LibreRouterOS Build Monitor"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start    Start monitoring build progress"
    echo "  logs     Follow build logs in real-time" 
    echo "  status   Check current build status"
    echo ""
fi