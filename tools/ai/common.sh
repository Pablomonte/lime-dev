#!/bin/bash

# AI Tools Common Functions
# Shared configuration and utilities for AI development tools

set -euo pipefail

# Configuration
AI_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_DEV_ROOT="$(cd "$AI_TOOLS_DIR/../.." && pwd)"
REPOS_DIR="$LIME_DEV_ROOT/repos"

# Supported repositories
SUPPORTED_REPOS=("lime-app" "lime-packages" "librerouteros")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Repository validation
validate_repo() {
    local repo="$1"
    
    if [[ "$repo" == "all" ]]; then
        return 0
    fi
    
    if [[ ! " ${SUPPORTED_REPOS[*]} " =~ " ${repo} " ]]; then
        log_error "Unsupported repository: $repo"
        log_info "Supported repositories: ${SUPPORTED_REPOS[*]} all"
        return 1
    fi
    
    if [[ ! -d "$REPOS_DIR/$repo" ]]; then
        log_error "Repository directory not found: $REPOS_DIR/$repo"
        log_info "Run './scripts/lime setup' to initialize repositories"
        return 1
    fi
    
    return 0
}

# Get repository list
get_repo_list() {
    local repo="$1"
    
    if [[ "$repo" == "all" ]]; then
        for r in "${SUPPORTED_REPOS[@]}"; do
            if [[ -d "$REPOS_DIR/$r" ]]; then
                echo "$r"
            fi
        done
    else
        echo "$repo"
    fi
}

# Repository type detection
detect_repo_type() {
    local repo_path="$1"
    
    if [[ -f "$repo_path/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$repo_path/Makefile" ]] && [[ -f "$repo_path/Config.in" ]]; then
        echo "openwrt"
    elif [[ -f "$repo_path/Makefile" ]]; then
        echo "makefile"
    else
        echo "generic"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# AI tools availability check
check_ai_tools() {
    local missing_tools=()
    local install_commands=()
    
    # Check for essential tools
    if ! command_exists "jq"; then
        missing_tools+=("jq")
    fi
    
    if ! command_exists "rg"; then
        missing_tools+=("ripgrep")
    fi
    
    if ! command_exists "python3"; then
        missing_tools+=("python3")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        
        # Provide platform-specific installation instructions
        if command_exists "apt-get"; then
            install_commands+=("sudo apt-get update && sudo apt-get install -y jq ripgrep python3")
        elif command_exists "yum"; then
            install_commands+=("sudo yum install -y jq ripgrep python3")
        elif command_exists "dnf"; then
            install_commands+=("sudo dnf install -y jq ripgrep python3")
        elif command_exists "pacman"; then
            install_commands+=("sudo pacman -S jq ripgrep python")
        elif command_exists "brew"; then
            install_commands+=("brew install jq ripgrep python3")
        fi
        
        if [[ ${#install_commands[@]} -gt 0 ]]; then
            log_info "Install with: ${install_commands[0]}"
        else
            log_info "Please install the missing tools for your platform"
        fi
        
        return 1
    fi
    
    return 0
}

# Install AI tools dependencies automatically
install_ai_dependencies() {
    log_info "Installing AI tools dependencies..."
    
    if command_exists "apt-get"; then
        sudo apt-get update
        sudo apt-get install -y jq ripgrep python3
    elif command_exists "yum"; then
        sudo yum install -y jq ripgrep python3
    elif command_exists "dnf"; then
        sudo dnf install -y jq ripgrep python3
    elif command_exists "pacman"; then
        sudo pacman -S --noconfirm jq ripgrep python
    elif command_exists "brew"; then
        brew install jq ripgrep python3
    else
        log_error "Unable to automatically install dependencies on this platform"
        log_info "Please manually install: jq, ripgrep, python3"
        return 1
    fi
    
    log_success "AI tools dependencies installed"
    return 0
}

# Generate summary report
generate_summary() {
    local tool_name="$1"
    local repo="$2"
    local status="$3"
    local details="$4"
    
    cat << EOF

================================================================================
AI Tool Summary: $tool_name
================================================================================
Repository: $repo
Status: $status
Timestamp: $(date)

$details

EOF
}

# Usage help
show_usage() {
    local tool_name="$1"
    local description="$2"
    
    cat << EOF
Usage: $tool_name [OPTIONS] --repo <repository>

$description

OPTIONS:
    --repo <name>       Repository to analyze (${SUPPORTED_REPOS[*]} all)
    --output <file>     Output file for results (default: stdout)
    --format <format>   Output format (text, json, markdown)
    --verbose           Enable verbose output
    --help              Show this help message

EXAMPLES:
    $tool_name --repo lime-app
    $tool_name --repo all --output results.txt
    $tool_name --repo lime-packages --format json
    
EOF
}

# Parse common command line arguments
parse_common_args() {
    REPO=""
    OUTPUT_FILE=""
    FORMAT="text"
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo)
                REPO="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                return 1
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    if [[ -z "$REPO" ]]; then
        log_error "Repository must be specified with --repo"
        return 1
    fi
    
    return 0
}

# Output formatting
format_output() {
    local content="$1"
    local format="$2"
    local output_file="$3"
    
    case "$format" in
        json)
            # Convert to JSON format
            echo "{\"content\": \"$content\", \"timestamp\": \"$(date -Iseconds)\"}"
            ;;
        markdown)
            # Format as markdown
            echo "# AI Tool Report"
            echo ""
            echo "**Timestamp:** $(date)"
            echo ""
            echo "$content"
            ;;
        *)
            echo "$content"
            ;;
    esac | if [[ -n "$output_file" ]]; then
        tee "$output_file"
    else
        cat
    fi
}