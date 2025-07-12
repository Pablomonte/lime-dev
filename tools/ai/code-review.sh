#!/bin/bash

# AI Code Review Tool
# Performs automated code review analysis across LibreMesh repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tool-specific configuration
TOOL_NAME="code-review"
DESCRIPTION="Automated code review with AI-assisted analysis"

# Code quality checks
check_code_quality() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Analyzing code quality in $repo_path"
    
    # Common checks for all repositories
    results+="=== File Structure Analysis ===\n"
    
    # Check for large files
    local large_files
    large_files=$(find "$repo_path" -type f -size +1M -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)
    if [[ -n "$large_files" ]]; then
        results+="⚠️  Large files detected:\n$large_files\n\n"
    else
        results+="✅ No large files detected\n\n"
    fi
    
    # Check for TODO/FIXME comments
    local todo_count
    todo_count=$(rg -i "todo|fixme|hack|xxx" "$repo_path" --type-not binary -c 2>/dev/null | wc -l || echo "0")
    results+="📝 TODO/FIXME comments: $todo_count\n\n"
    
    # Repository-specific checks
    case "$repo_type" in
        nodejs)
            results+="=== Node.js Specific Analysis ===\n"
            results+="$(check_nodejs_quality "$repo_path")\n\n"
            ;;
        openwrt)
            results+="=== OpenWrt Specific Analysis ===\n"
            results+="$(check_openwrt_quality "$repo_path")\n\n"
            ;;
        makefile)
            results+="=== Makefile Project Analysis ===\n"
            results+="$(check_makefile_quality "$repo_path")\n\n"
            ;;
    esac
    
    echo -e "$results"
}

# Node.js specific quality checks
check_nodejs_quality() {
    local repo_path="$1"
    local results=""
    
    # Check package.json
    if [[ -f "$repo_path/package.json" ]]; then
        results+="✅ package.json found\n"
        
        # Check for security vulnerabilities in dependencies
        if command_exists npm; then
            cd "$repo_path"
            local audit_result
            audit_result=$(npm audit --audit-level moderate 2>/dev/null || echo "audit failed")
            if [[ "$audit_result" != "audit failed" ]]; then
                results+="🔒 Security audit: $(echo "$audit_result" | grep -c "vulnerabilities" || echo "0") issues\n"
            fi
            cd - >/dev/null
        fi
        
        # Check for TypeScript
        if jq -e '.devDependencies.typescript' "$repo_path/package.json" >/dev/null 2>&1; then
            results+="✅ TypeScript configuration detected\n"
        fi
    fi
    
    # Check for linting configuration
    if [[ -f "$repo_path/.eslintrc.js" ]] || [[ -f "$repo_path/.eslintrc.json" ]]; then
        results+="✅ ESLint configuration found\n"
    fi
    
    # Check for testing
    if [[ -d "$repo_path/tests" ]] || [[ -d "$repo_path/test" ]] || [[ -d "$repo_path/src/__tests__" ]]; then
        results+="✅ Test directory found\n"
    fi
    
    echo -e "$results"
}

# OpenWrt specific quality checks
check_openwrt_quality() {
    local repo_path="$1"
    local results=""
    
    # Check for Makefile
    if [[ -f "$repo_path/Makefile" ]]; then
        results+="✅ Makefile found\n"
        
        # Check for proper OpenWrt structure
        if grep -q "include.*rules.mk" "$repo_path/Makefile"; then
            results+="✅ OpenWrt Makefile structure detected\n"
        fi
    fi
    
    # Check for feeds configuration
    if [[ -f "$repo_path/feeds.conf" ]] || [[ -f "$repo_path/feeds.conf.default" ]]; then
        results+="✅ Feeds configuration found\n"
    fi
    
    # Check for kernel configuration
    if [[ -d "$repo_path/target" ]]; then
        results+="✅ Target configuration directory found\n"
    fi
    
    # Check for package structure
    local package_count
    package_count=$(find "$repo_path" -name "Makefile" -path "*/package/*" | wc -l)
    results+="📦 Package makefiles: $package_count\n"
    
    echo -e "$results"
}

# Makefile project quality checks
check_makefile_quality() {
    local repo_path="$1"
    local results=""
    
    # Check Makefile syntax
    if [[ -f "$repo_path/Makefile" ]]; then
        results+="✅ Makefile found\n"
        
        # Check for common Makefile targets
        local common_targets=("all" "clean" "install" "test")
        for target in "${common_targets[@]}"; do
            if grep -q "^$target:" "$repo_path/Makefile"; then
                results+="✅ Target '$target' found\n"
            fi
        done
    fi
    
    echo -e "$results"
}

# Security analysis
check_security() {
    local repo_path="$1"
    local results=""
    
    log_info "Performing security analysis"
    
    results+="=== Security Analysis ===\n"
    
    # Check for potential security issues
    local security_patterns=(
        "password.*="
        "api[_-]?key.*="
        "secret.*="
        "token.*="
        "credential.*="
    )
    
    local security_issues=0
    for pattern in "${security_patterns[@]}"; do
        local matches
        matches=$(rg -i "$pattern" "$repo_path" --type-not binary -c 2>/dev/null || echo "0")
        if [[ "$matches" -gt 0 ]]; then
            security_issues=$((security_issues + matches))
        fi
    done
    
    if [[ $security_issues -eq 0 ]]; then
        results+="✅ No obvious security issues detected\n"
    else
        results+="⚠️  Potential security issues: $security_issues patterns found\n"
    fi
    
    # Check for hardcoded IPs
    local ip_matches
    ip_matches=$(rg -E "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b" "$repo_path" --type-not binary -c 2>/dev/null || echo "0")
    results+="🌐 Hardcoded IP addresses: $ip_matches occurrences\n"
    
    echo -e "$results"
}

# Main code review function
perform_code_review() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local repo_type
    
    log_info "Starting code review for $repo"
    
    repo_type=$(detect_repo_type "$repo_path")
    log_info "Detected repository type: $repo_type"
    
    local review_results=""
    review_results+="Repository: $repo ($repo_type)\n"
    review_results+="Path: $repo_path\n\n"
    
    # Perform quality checks
    review_results+="$(check_code_quality "$repo_path" "$repo_type")\n"
    
    # Perform security checks
    review_results+="$(check_security "$repo_path")\n"
    
    # Generate summary
    local status="COMPLETED"
    generate_summary "$TOOL_NAME" "$repo" "$status" "$review_results"
}

# Main execution
main() {
    if ! parse_common_args "$@"; then
        show_usage "$TOOL_NAME" "$DESCRIPTION"
        exit 1
    fi
    
    if ! validate_repo "$REPO"; then
        exit 1
    fi
    
    if ! check_ai_tools; then
        log_error "Required tools are missing. AI analysis cannot proceed."
        log_info "Run 'sudo ./tools/ai/install-dependencies.sh' to install required tools"
        exit 1
    fi
    
    local all_results=""
    
    for repo in $(get_repo_list "$REPO"); do
        if [[ $VERBOSE == true ]]; then
            log_info "Processing repository: $repo"
        fi
        
        local repo_results
        repo_results=$(perform_code_review "$repo")
        all_results+="$repo_results\n\n"
    done
    
    # Format and output results
    format_output "$all_results" "$FORMAT" "$OUTPUT_FILE"
    
    log_success "Code review completed"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi