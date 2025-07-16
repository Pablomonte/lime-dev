#!/usr/bin/env bash
#
# Dependency Graph Generator for LibreMesh Development Environment
# Generates visual representation of repository dependencies from config file
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_DEV_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$LIME_DEV_ROOT/configs/versions.conf"
REPOS_DIR="$LIME_DEV_ROOT/repos"

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

print_success() {
    echo "[SUCCESS] $1"
}

# Parse config file and extract repository information
parse_config() {
    local section="$1"
    local output_var="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Use associative array to store repo info
    declare -g -A repo_info
    
    local in_section=false
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$section" ]]; then
                in_section=true
            else
                in_section=false
            fi
            continue
        fi
        
        # Parse key=value pairs in the target section
        if [[ "$in_section" == true && "$line" =~ ^([^=]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Parse repository format: url|branch|remote
            if [[ "$value" =~ ^([^|]+)\|([^|]+)\|([^|]+)$ ]]; then
                local url="${BASH_REMATCH[1]}"
                local branch="${BASH_REMATCH[2]}"
                local remote="${BASH_REMATCH[3]}"
                
                repo_info["${key}_url"]="$url"
                repo_info["${key}_branch"]="$branch"
                repo_info["${key}_remote"]="$remote"
                repo_info["${key}_name"]="$key"
            fi
        fi
    done < "$CONFIG_FILE"
}

# Get repository status information
get_repo_status() {
    local repo_name="$1"
    local repo_path="$REPOS_DIR/$repo_name"
    
    if [[ ! -d "$repo_path" ]]; then
        echo "MISSING"
        return 1
    fi
    
    cd "$repo_path"
    
    local current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    local current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local changes=$(git status --porcelain 2>/dev/null | wc -l)
    local ahead_count=0
    
    # Check if branch has upstream tracking
    local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
    if [[ -n "$upstream" ]]; then
        ahead_count=$(git rev-list --count HEAD ^"$upstream" 2>/dev/null || echo "0")
    fi
    
    local status="CLEAN"
    if [[ $changes -gt 0 ]]; then
        status="MODIFIED($changes)"
    elif [[ $ahead_count -gt 0 ]]; then
        status="AHEAD($ahead_count)"
    fi
    
    echo "$current_branch:$current_commit:$status"
    cd "$LIME_DEV_ROOT"
}

# Utility function to truncate long text
truncate_text() {
    local text="$1"
    local max_length="$2"
    
    if [[ ${#text} -gt $max_length ]]; then
        echo "${text:0:$((max_length-3))}..."
    else
        echo "$text"
    fi
}

# Format repository status in compact form
format_repo_status() {
    local repo_name="$1"
    local status_info=$(get_repo_status "$repo_name")
    
    if [[ "$status_info" == "MISSING" ]]; then
        echo "MISSING"
        return
    fi
    
    IFS=':' read -r branch commit status <<< "$status_info"
    
    # Truncate long branch names
    local short_branch=$(truncate_text "$branch" 18)
    local short_commit="${commit:0:7}"
    
    # Create compact status
    case "$status" in
        "CLEAN")
            echo "$short_branch:$short_commit"
            ;;
        "MODIFIED"*)
            local count=$(echo "$status" | grep -o '[0-9]\+')
            echo "$short_branch:$short_commit:M($count)"
            ;;
        "AHEAD"*)
            local count=$(echo "$status" | grep -o '[0-9]\+')
            echo "$short_branch:$short_commit:A($count)"
            ;;
        *)
            echo "$short_branch:$short_commit"
            ;;
    esac
}

# Generate ASCII dependency graph
generate_ascii_graph() {
    local graph_type="${1:-repositories}"
    
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║            LibreMesh Development Dependencies                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    parse_config "$graph_type"
    
    # Define dependency relationships
    declare -A dependencies
    dependencies["librerouteros"]="openwrt lime_packages"
    dependencies["lime_packages"]="openwrt"
    dependencies["lime_app"]="lime_packages"
    dependencies["kconfig_utils"]=""
    dependencies["openwrt"]=""
    
    # Color codes for status
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local CYAN='\033[0;36m'
    local NC='\033[0m' # No Color
    
    # Generate the graph
    echo "Dependencies & Status:"
    echo "====================="
    echo ""
    
    # Helper function to get colored status for tree display
    get_colored_status() {
        local repo_name="$1"
        local status_info=$(get_repo_status "$repo_name")
        
        if [[ "$status_info" == "MISSING" ]]; then
            echo -e "${RED}MISSING${NC}"
            return
        fi
        
        IFS=':' read -r branch commit status <<< "$status_info"
        
        # Determine color based on status
        local color="$GREEN"
        local status_text="$status"
        
        case "$status" in
            "CLEAN")
                color="$GREEN"
                status_text="clean"
                ;;
            "MODIFIED"*)
                color="$YELLOW"
                local count=$(echo "$status" | grep -o '[0-9]\+')
                status_text="modified ($count changes)"
                ;;
            "AHEAD"*)
                color="$YELLOW"
                local count=$(echo "$status" | grep -o '[0-9]\+')
                status_text="ahead ($count commits)"
                ;;
        esac
        
        echo -e "${color}${branch}${NC} (${commit:0:7}) - ${color}${status_text}${NC}"
    }
    
    # Tree-style dependency visualization
    echo "Dependency Tree:"
    echo "==============="
    echo ""
    
    # Root: OpenWrt (base dependency)
    echo -e "├── ${BLUE}OpenWrt${NC} (Base OS)"
    echo -e "│   $(get_colored_status "openwrt")"
    echo "│"
    
    # Level 1: LibreMesh Packages (depends on OpenWrt)
    echo -e "├── ${GREEN}LibreMesh Packages${NC} (Mesh networking) ${BLUE}[depends: OpenWrt]${NC}"
    echo -e "│   $(get_colored_status "lime-packages")"
    echo "│"
    
    # Level 2: Applications that depend on LibreMesh Packages
    echo -e "│   ├── ${CYAN}Lime-App${NC} (Web Interface) ${BLUE}[depends: LibreMesh Packages]${NC}"
    echo -e "│   │   $(get_colored_status "lime-app")"
    echo "│   │"
    echo -e "│   └── ${GREEN}LibreRouterOS${NC} (Firmware) ${BLUE}[depends: OpenWrt + LibreMesh]${NC}"
    echo -e "│       $(get_colored_status "librerouteros")"
    echo "│"
    
    # Independent tools
    echo -e "└── ${BLUE}KConfig Utils${NC} (Development tool) ${BLUE}[independent]${NC}"
    echo -e "    $(get_colored_status "kconfig-utils")"
    echo ""
    
    # Legend
    echo -e "Status: ${GREEN}●${NC}Clean ${YELLOW}●${NC}Modified/Ahead ${RED}●${NC}Missing ${BLUE}●${NC}Independent/Base"
    echo ""
    
    # Compact status table
    echo "Repository Details:"
    echo "==================="
    printf "%-15s %-20s %-12s %-s\n" "Repository" "Branch" "Commit" "Status"
    echo "$(printf '%*s' 70 '' | tr ' ' '-')"
    
    for repo in openwrt lime-packages kconfig-utils lime-app librerouteros; do
        local status_info=$(get_repo_status "$repo")
        
        if [[ "$status_info" != "MISSING" ]]; then
            IFS=':' read -r branch commit status <<< "$status_info"
            local short_branch=$(truncate_text "$branch" 18)
            local short_commit="${commit:0:7}"
            printf "%-15s %-20s %-12s %-s\n" "$repo" "$short_branch" "$short_commit" "$status"
        else
            printf "%-15s %-20s %-12s %-s\n" "$repo" "N/A" "N/A" "MISSING"
        fi
    done
    echo ""
}

# Generate DOT format for Graphviz
generate_dot_graph() {
    local output_file="${1:-dependency-graph.dot}"
    
    parse_config "repositories"
    
    cat > "$output_file" << 'EOF'
digraph LibreMeshDependencies {
    rankdir=TB;
    node [shape=box, style=filled];
    
    // Define node styles based on repository type
    subgraph cluster_base {
        label="Base System";
        style=filled;
        color=lightgrey;
        openwrt [label="OpenWrt\n(Base OS)", fillcolor=lightblue];
    }
    
    subgraph cluster_mesh {
        label="LibreMesh Stack";
        style=filled;
        color=lightgreen;
        lime_packages [label="LibreMesh\nPackages", fillcolor=lightgreen];
        lime_app [label="Lime-App\n(Web UI)", fillcolor=lightcyan];
    }
    
    subgraph cluster_firmware {
        label="Firmware";
        style=filled;
        color=lightyellow;
        librerouteros [label="LibreRouterOS\n(Firmware)", fillcolor=lightyellow];
    }
    
    subgraph cluster_tools {
        label="Development Tools";
        style=filled;
        color=lavender;
        kconfig_utils [label="KConfig\nUtils", fillcolor=lavender];
    }
    
    // Define dependencies
    openwrt -> lime_packages [label="provides kernel"];
    openwrt -> librerouteros [label="base system"];
    lime_packages -> lime_app [label="mesh services"];
    lime_packages -> librerouteros [label="mesh packages"];
    
    // Independent tools
    kconfig_utils [style=dashed];
}
EOF
    
    print_success "DOT graph generated: $output_file"
    print_info "Generate PNG with: dot -Tpng $output_file -o dependency-graph.png"
}

# Show configuration summary
show_config_summary() {
    echo "Configuration Summary from $CONFIG_FILE:"
    echo "========================================"
    echo ""
    
    # Parse and display each section
    local current_section=""
    while IFS= read -r line; do
        # Skip comments and empty lines for cleaner output
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Section headers
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            echo "[$current_section]"
            continue
        fi
        
        # Key=value pairs
        if [[ "$line" =~ ^([^=]+)=(.+)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            echo "  $key = $value"
        fi
    done < "$CONFIG_FILE"
    echo ""
}

# Main function
main() {
    local command="${1:-ascii}"
    local output_file="${2:-dependency-graph.dot}"
    
    case "$command" in
        "ascii"|"graph"|"tree")
            generate_ascii_graph "repositories"
            ;;
        "dot"|"graphviz")
            generate_dot_graph "$output_file"
            ;;
        "config"|"summary")
            show_config_summary
            ;;
        "release")
            print_info "Release mode dependency graph:"
            generate_ascii_graph "release_overrides"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command] [output_file]"
            echo ""
            echo "Commands:"
            echo "  ascii, graph, tree    Show ASCII dependency graph (default)"
            echo "  dot, graphviz        Generate DOT file for Graphviz"
            echo "  config, summary      Show configuration summary"
            echo "  release              Show release mode dependencies"
            echo "  help                 Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Show ASCII graph"
            echo "  $0 dot deps.dot             # Generate DOT file"
            echo "  $0 config                   # Show config summary"
            echo "  $0 release                  # Show release dependencies"
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"