#!/bin/bash

# Upstream Git Aliases Setup
# Configures multi-repo git aliases for upstream contribution workflows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIME_DEV_ROOT="$(cd "$TOOLS_DIR/.." && pwd)"
REPOS_DIR="$LIME_DEV_ROOT/repos"

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

# Repository configuration
declare -A REPO_UPSTREAMS=(
    ["lime-app"]="https://github.com/libremesh/lime-app.git"
    ["lime-packages"]="https://github.com/libremesh/lime-packages.git"
    ["librerouteros"]="https://github.com/librerouteros/librerouteros.git"
)

declare -A REPO_BRANCHES=(
    ["lime-app"]="master"
    ["lime-packages"]="master" 
    ["librerouteros"]="main"
)

# Check if repository exists
check_repository() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    
    if [[ ! -d "$repo_path" ]]; then
        log_error "Repository $repo not found at $repo_path"
        return 1
    fi
    
    if [[ ! -d "$repo_path/.git" ]]; then
        log_error "Repository $repo is not a git repository"
        return 1
    fi
    
    return 0
}

# Setup upstream remote
setup_upstream_remote() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local upstream_url="${REPO_UPSTREAMS[$repo]}"
    
    log_info "Setting up upstream remote for $repo"
    
    cd "$repo_path"
    
    # Check if upstream remote already exists
    if git remote | grep -q "^upstream$"; then
        local current_upstream
        current_upstream=$(git remote get-url upstream)
        if [[ "$current_upstream" == "$upstream_url" ]]; then
            log_success "Upstream remote already configured correctly"
        else
            log_warning "Upstream remote exists with different URL: $current_upstream"
            log_info "Updating upstream remote to: $upstream_url"
            git remote set-url upstream "$upstream_url"
        fi
    else
        log_info "Adding upstream remote: $upstream_url"
        git remote add upstream "$upstream_url"
    fi
    
    # Fetch upstream
    log_info "Fetching upstream changes..."
    git fetch upstream
    
    log_success "Upstream remote configured for $repo"
}

# Setup git aliases for upstream workflow
setup_git_aliases() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local main_branch="${REPO_BRANCHES[$repo]}"
    
    log_info "Setting up git aliases for $repo"
    
    cd "$repo_path"
    
    # Upstream workflow aliases
    git config alias.upstream-status "!git log --oneline --graph origin/$main_branch..upstream/$main_branch"
    git config alias.upstream-sync "!git checkout $main_branch && git pull upstream $main_branch && git push origin $main_branch"
    git config alias.upstream-merge "!git checkout $main_branch && git merge upstream/$main_branch"
    git config alias.upstream-rebase "!git checkout $main_branch && git rebase upstream/$main_branch"
    
    # Feature branch workflow
    git config alias.feature-start "!f() { git checkout $main_branch && git pull upstream $main_branch && git checkout -b \"\$1\"; }; f"
    git config alias.feature-sync "!git fetch upstream && git rebase upstream/$main_branch"
    git config alias.feature-finish "!f() { git checkout $main_branch && git merge --no-ff \"\$1\" && git branch -d \"\$1\"; }; f"
    
    # Clean contribution workflow
    git config alias.clean-for-upstream "!f() { \
        git checkout $main_branch && \
        git pull upstream $main_branch && \
        git push origin $main_branch && \
        git branch --merged | grep -v '\\*\\|$main_branch' | xargs -n 1 git branch -d; \
    }; f"
    
    # Upstream patch creation
    git config alias.create-patch "!f() { \
        git format-patch upstream/$main_branch..\"\${1:-HEAD}\" --output-directory=patches/; \
    }; f"
    
    # Review helpers
    git config alias.review-changes "!git diff upstream/$main_branch...HEAD"
    git config alias.review-commits "!git log --oneline upstream/$main_branch..HEAD"
    
    log_success "Git aliases configured for $repo"
}

# Create upstream exclusion patterns
create_exclusion_config() {
    local repo="$1"
    local config_file="$SCRIPT_DIR/configs/${repo}.exclude"
    
    log_info "Creating exclusion configuration for $repo"
    
    # Repository-specific exclusions
    case "$repo" in
        "lime-app")
            cat > "$config_file" << 'EOF'
# lime-app upstream exclusions
# Files and patterns that should not be included in upstream contributions

# Development infrastructure
scripts/ai-*.sh
scripts/verify-*.sh
scripts/setup-upstream-*.sh
.upstream-exclude
tools/
*.dev.*
*-dev.*

# Local development configurations
.vscode/
.devcontainer/
docker-compose.override.yml
.env.local
.env.development

# Build artifacts and caches
node_modules/
dist/
build/
coverage/
.nyc_output/
*.log

# IDE and editor files
.idea/
*.swp
*.swo
*~
.DS_Store

# Git hooks and local scripts
.git/hooks/
pre-commit
post-commit
EOF
            ;;
        "lime-packages")
            cat > "$config_file" << 'EOF'
# lime-packages upstream exclusions
# Files and patterns that should not be included in upstream contributions

# Development infrastructure
scripts/dev-*.sh
scripts/qemu-dev-*
tools/

# Local QEMU configurations
qemu-local-*.sh
*-local.conf
lime_tap*
lime_br*

# Build outputs and temporary files
build/
cache/
tmp/
*.tmp
*.bak

# Local testing configurations
test-configs/
local-feeds.conf
.buildinfo

# Development documentation
DEVELOPMENT.md
HACKING.md
*.dev.md
EOF
            ;;
        "librerouteros")
            cat > "$config_file" << 'EOF'
# librerouteros upstream exclusions
# Files and patterns that should not be included in upstream contributions

# Development infrastructure
scripts/dev-*.sh
tools/

# Local build configurations
.config.local
defconfig.local
local-feeds.conf

# Build artifacts
build_dir/
staging_dir/
tmp/
logs/
*.log

# Development packages
package/development/

# Local patches and modifications
patches/local/
files/local/

# Testing and development documentation
*.dev.md
TESTING.md
EOF
            ;;
    esac
    
    log_success "Exclusion configuration created: $config_file"
}

# Setup pre-commit hook for upstream readiness
setup_upstream_hooks() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local hook_file="$repo_path/.git/hooks/pre-commit"
    
    log_info "Setting up upstream readiness hooks for $repo"
    
    # Create pre-commit hook
    cat > "$hook_file" << 'EOF'
#!/bin/bash
# Pre-commit hook for upstream contribution readiness

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
TOOLS_DIR="$(git rev-parse --show-toplevel)/../../tools"

# Check if this is an upstream-ready commit
if git log -1 --pretty=%B | grep -q "\\[upstream\\]"; then
    echo "Checking upstream readiness..."
    
    # Run upstream validation
    if [[ -x "$TOOLS_DIR/upstream/validate-commit.sh" ]]; then
        "$TOOLS_DIR/upstream/validate-commit.sh" --repo "$REPO_NAME" --staged
    fi
fi
EOF
    
    chmod +x "$hook_file"
    log_success "Pre-commit hook installed for $repo"
}

# Setup repository for upstream contribution
setup_repository() {
    local repo="$1"
    
    log_info "Setting up $repo for upstream contribution"
    
    if ! check_repository "$repo"; then
        return 1
    fi
    
    setup_upstream_remote "$repo"
    setup_git_aliases "$repo"
    create_exclusion_config "$repo"
    setup_upstream_hooks "$repo"
    
    log_success "Repository $repo configured for upstream contribution"
}

# List available aliases
show_aliases() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    
    if ! check_repository "$repo"; then
        return 1
    fi
    
    echo "Git aliases for $repo:"
    echo "======================"
    
    cd "$repo_path"
    
    cat << 'EOF'
Upstream synchronization:
  git upstream-status    - Show commits in upstream not in origin
  git upstream-sync      - Sync main branch with upstream
  git upstream-merge     - Merge upstream changes
  git upstream-rebase    - Rebase on upstream

Feature development:
  git feature-start <name>  - Start new feature branch from upstream
  git feature-sync          - Sync feature branch with upstream
  git feature-finish <name> - Merge feature branch and cleanup

Contribution workflow:
  git clean-for-upstream    - Clean merged branches and sync
  git create-patch [branch] - Create patch files for upstream
  git review-changes        - Review changes vs upstream
  git review-commits        - List commits not in upstream

Usage examples:
  git feature-start my-new-feature
  git feature-sync
  git create-patch
  git upstream-sync
EOF
}

# Main execution
main() {
    local action="${1:-setup}"
    local repo="${2:-all}"
    
    case "$action" in
        "setup")
            if [[ "$repo" == "all" ]]; then
                for r in "${!REPO_UPSTREAMS[@]}"; do
                    if [[ -d "$REPOS_DIR/$r" ]]; then
                        setup_repository "$r"
                        echo ""
                    fi
                done
            else
                setup_repository "$repo"
            fi
            ;;
        "aliases")
            if [[ "$repo" == "all" ]]; then
                for r in "${!REPO_UPSTREAMS[@]}"; do
                    if [[ -d "$REPOS_DIR/$r" ]]; then
                        show_aliases "$r"
                        echo ""
                    fi
                done
            else
                show_aliases "$repo"
            fi
            ;;
        "help")
            cat << 'EOF'
Usage: setup-aliases.sh [ACTION] [REPO]

ACTIONS:
    setup     - Setup upstream configuration (default)
    aliases   - Show available git aliases
    help      - Show this help

REPOS:
    lime-app       - Setup lime-app repository
    lime-packages  - Setup lime-packages repository  
    librerouteros  - Setup librerouteros repository
    all           - Setup all repositories (default)

EXAMPLES:
    ./setup-aliases.sh setup lime-app
    ./setup-aliases.sh aliases all
    ./setup-aliases.sh setup
EOF
            ;;
        *)
            log_error "Unknown action: $action"
            main "help"
            exit 1
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Create configs directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/configs"
    main "$@"
fi