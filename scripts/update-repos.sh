#!/usr/bin/env bash
#
# Update all repositories in repos/ directory
# Fetches latest changes and pulls from appropriate branches
#

set -e

WORK_DIR="$(pwd)"
REPOS_DIR="$WORK_DIR/repos"

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

print_success() {
    echo "[SUCCESS] $1"
}

# Check if running from lime-build directory
check_directory() {
    if [[ ! "$(basename "$PWD")" == "lime-build" ]]; then
        print_error "This script should be run from the lime-build directory"
        exit 1
    fi
    
    if [[ ! -d "repos" ]]; then
        print_error "repos/ directory not found. Run setup-lime-dev.sh first."
        exit 1
    fi
}

# Update a specific repository
update_repo() {
    local repo_name="$1"
    local default_branch="$2"
    local repo_path="$REPOS_DIR/$repo_name"
    
    if [[ ! -d "$repo_path" ]]; then
        print_error "$repo_name not found in repos/"
        return 1
    fi
    
    print_info "Updating $repo_name..."
    cd "$repo_path"
    
    # Get current branch
    current_branch=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD)
    
    # Fetch all remotes
    print_info "  Fetching from all remotes..."
    git fetch --all --prune
    
    # Check if we're on a detached HEAD (like OpenWrt tag)
    if [[ "$current_branch" == "HEAD" ]] || git rev-parse --verify HEAD >/dev/null 2>&1 && ! git symbolic-ref HEAD >/dev/null 2>&1; then
        print_info "  Repository is on detached HEAD (likely a tag), skipping pull"
    else
        # Pull from current branch or default
        local branch_to_pull="${current_branch:-$default_branch}"
        print_info "  Pulling from origin/$branch_to_pull..."
        
        if git show-ref --verify --quiet "refs/remotes/origin/$branch_to_pull"; then
            git pull origin "$branch_to_pull"
            print_success "  $repo_name updated successfully"
        else
            print_error "  Branch origin/$branch_to_pull not found, skipping pull"
        fi
    fi
    
    # Show current status
    local current_commit=$(git rev-parse --short HEAD)
    local current_ref=$(git describe --tags --exact-match 2>/dev/null || git branch --show-current 2>/dev/null || echo "detached")
    print_info "  Current: $current_ref ($current_commit)"
    
    cd "$WORK_DIR"
}

# Update all repositories
update_all_repos() {
    print_info "Updating all repositories in repos/ directory..."
    
    # Update each repository with its appropriate default branch
    update_repo "lime-app" "master"
    update_repo "lime-packages" "master" 
    update_repo "librerouteros" "librerouter-1.5"
    update_repo "kconfig-utils" "master"
    
    # Special handling for OpenWrt (tagged version)
    if [[ -d "$REPOS_DIR/openwrt" ]]; then
        print_info "Checking OpenWrt status..."
        cd "$REPOS_DIR/openwrt"
        local current_tag=$(git describe --tags --exact-match 2>/dev/null || echo "none")
        print_info "  OpenWrt is at: $current_tag"
        cd "$WORK_DIR"
    fi
    
    print_success "All repositories updated!"
}

# Show repository status
show_status() {
    print_info "Repository status:"
    
    for repo in lime-app lime-packages librerouteros kconfig-utils openwrt; do
        if [[ -d "$REPOS_DIR/$repo" ]]; then
            cd "$REPOS_DIR/$repo"
            local current_commit=$(git rev-parse --short HEAD)
            local current_ref=$(git describe --tags --exact-match 2>/dev/null || git branch --show-current 2>/dev/null || echo "detached")
            local status=$(git status --porcelain | wc -l)
            local status_msg=""
            
            if [[ $status -gt 0 ]]; then
                status_msg=" (${status} changes)"
            fi
            
            echo "  $repo: $current_ref ($current_commit)$status_msg"
            cd "$WORK_DIR"
        else
            echo "  $repo: NOT FOUND"
        fi
    done
}

# Main function
main() {
    check_directory
    
    case "${1:-update}" in
        "update"|"pull")
            update_all_repos
            ;;
        "status"|"info")
            show_status
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  update, pull    Update all repositories (default)"
            echo "  status, info    Show repository status"
            echo "  help           Show this help"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"