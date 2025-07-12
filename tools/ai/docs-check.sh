#!/bin/bash

# AI Documentation Check Tool
# Validates documentation completeness across LibreMesh repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tool-specific configuration
TOOL_NAME="docs-check"
DESCRIPTION="Documentation completeness verification"

# Documentation requirements by repository type
declare -A DOC_REQUIREMENTS=(
    ["nodejs"]="README.md package.json docs/ src/"
    ["openwrt"]="README.md Makefile Config.in"
    ["makefile"]="README.md Makefile"
    ["generic"]="README.md"
)

# Check documentation completeness
check_documentation() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Checking documentation in $repo_path"
    
    results+="=== Documentation Analysis ===\n"
    
    # Check for required files
    local requirements="${DOC_REQUIREMENTS[$repo_type]}"
    local missing_files=()
    local found_files=()
    
    for req in $requirements; do
        if [[ -e "$repo_path/$req" ]]; then
            found_files+=("$req")
        else
            missing_files+=("$req")
        fi
    done
    
    # Report findings
    if [[ ${#found_files[@]} -gt 0 ]]; then
        results+="✅ Found documentation files:\n"
        for file in "${found_files[@]}"; do
            results+="   - $file\n"
        done
        results+="\n"
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        results+="⚠️  Missing documentation files:\n"
        for file in "${missing_files[@]}"; do
            results+="   - $file\n"
        done
        results+="\n"
    fi
    
    # Check README.md quality
    if [[ -f "$repo_path/README.md" ]]; then
        results+="$(check_readme_quality "$repo_path/README.md")\n\n"
    fi
    
    # Check inline documentation
    results+="$(check_inline_docs "$repo_path" "$repo_type")\n\n"
    
    echo -e "$results"
}

# Check README.md quality
check_readme_quality() {
    local readme_path="$1"
    local results=""
    
    results+="=== README.md Analysis ===\n"
    
    local line_count
    line_count=$(wc -l < "$readme_path")
    results+="📄 Lines: $line_count\n"
    
    # Check for essential sections
    local essential_sections=("# " "## " "Installation" "Usage" "Description")
    local found_sections=()
    
    for section in "${essential_sections[@]}"; do
        if grep -qi "$section" "$readme_path"; then
            found_sections+=("$section")
        fi
    done
    
    results+="📋 Essential sections found: ${#found_sections[@]}/${#essential_sections[@]}\n"
    
    # Check for code examples
    local code_blocks
    code_blocks=$(grep -c "```" "$readme_path" || echo "0")
    results+="💻 Code blocks: $((code_blocks / 2))\n"
    
    # Check for links
    local links
    links=$(grep -c "\[.*\](.*)" "$readme_path" || echo "0")
    results+="🔗 Links: $links\n"
    
    # Check for images
    local images
    images=$(grep -c "!\[.*\](.*)" "$readme_path" || echo "0")
    results+="🖼️  Images: $images\n"
    
    # Quality assessment
    local quality_score=0
    [[ $line_count -gt 20 ]] && quality_score=$((quality_score + 1))
    [[ ${#found_sections[@]} -ge 3 ]] && quality_score=$((quality_score + 1))
    [[ $((code_blocks / 2)) -gt 0 ]] && quality_score=$((quality_score + 1))
    [[ $links -gt 0 ]] && quality_score=$((quality_score + 1))
    
    case $quality_score in
        4) results+="🟢 README Quality: Excellent\n" ;;
        3) results+="🟡 README Quality: Good\n" ;;
        2) results+="🟠 README Quality: Fair\n" ;;
        *) results+="🔴 README Quality: Needs Improvement\n" ;;
    esac
    
    echo -e "$results"
}

# Check inline documentation
check_inline_docs() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Inline Documentation Analysis ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(check_js_docs "$repo_path")\n"
            ;;
        openwrt|makefile)
            results+="$(check_script_docs "$repo_path")\n"
            ;;
        *)
            results+="$(check_generic_docs "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# Check JavaScript/TypeScript documentation
check_js_docs() {
    local repo_path="$1"
    local results=""
    
    # Count JS/TS files
    local js_files
    js_files=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | grep -v node_modules | wc -l)
    results+="📁 JS/TS files: $js_files\n"
    
    if [[ $js_files -gt 0 ]]; then
        # Count JSDoc comments
        local jsdoc_comments
        jsdoc_comments=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | xargs grep -l "/\*\*" 2>/dev/null | wc -l)
        results+="📝 Files with JSDoc: $jsdoc_comments\n"
        
        # Calculate documentation ratio
        local doc_ratio=$((jsdoc_comments * 100 / js_files))
        results+="📊 Documentation ratio: $doc_ratio%\n"
        
        if [[ $doc_ratio -ge 70 ]]; then
            results+="🟢 Inline documentation: Excellent\n"
        elif [[ $doc_ratio -ge 40 ]]; then
            results+="🟡 Inline documentation: Good\n"
        elif [[ $doc_ratio -ge 20 ]]; then
            results+="🟠 Inline documentation: Fair\n"
        else
            results+="🔴 Inline documentation: Needs Improvement\n"
        fi
    fi
    
    echo -e "$results"
}

# Check shell script documentation
check_script_docs() {
    local repo_path="$1"
    local results=""
    
    # Count shell scripts
    local script_files
    script_files=$(find "$repo_path" -name "*.sh" -o -name "*.bash" | wc -l)
    results+="📁 Shell scripts: $script_files\n"
    
    if [[ $script_files -gt 0 ]]; then
        # Count scripts with headers
        local documented_scripts
        documented_scripts=$(find "$repo_path" -name "*.sh" -o -name "*.bash" | xargs grep -l "^#.*" | wc -l)
        results+="📝 Scripts with comments: $documented_scripts\n"
        
        # Calculate documentation ratio
        local doc_ratio=$((documented_scripts * 100 / script_files))
        results+="📊 Documentation ratio: $doc_ratio%\n"
    fi
    
    echo -e "$results"
}

# Check generic documentation
check_generic_docs() {
    local repo_path="$1"
    local results=""
    
    # Count all source files
    local source_files
    source_files=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.py" -o -name "*.go" -o -name "*.rs" | wc -l)
    results+="📁 Source files: $source_files\n"
    
    # Count comment lines
    local comment_lines
    comment_lines=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.py" -o -name "*.go" -o -name "*.rs" | xargs grep -h "^\s*#\|^\s*//\|^\s*/\*" 2>/dev/null | wc -l || echo "0")
    results+="💬 Comment lines: $comment_lines\n"
    
    echo -e "$results"
}

# Check for documentation consistency
check_consistency() {
    local repo_path="$1"
    local results=""
    
    results+="=== Documentation Consistency ===\n"
    
    # Check for consistent naming
    local readme_files
    readme_files=$(find "$repo_path" -iname "readme*" | wc -l)
    results+="📄 README variants: $readme_files\n"
    
    # Check for changelog
    if [[ -f "$repo_path/CHANGELOG.md" ]] || [[ -f "$repo_path/HISTORY.md" ]]; then
        results+="✅ Changelog found\n"
    else
        results+="⚠️  No changelog found\n"
    fi
    
    # Check for license
    if [[ -f "$repo_path/LICENSE" ]] || [[ -f "$repo_path/LICENSE.txt" ]] || [[ -f "$repo_path/LICENSE.md" ]]; then
        results+="✅ License file found\n"
    else
        results+="⚠️  No license file found\n"
    fi
    
    # Check for contributing guide
    if [[ -f "$repo_path/CONTRIBUTING.md" ]]; then
        results+="✅ Contributing guide found\n"
    else
        results+="ℹ️  No contributing guide found\n"
    fi
    
    echo -e "$results"
}

# Main documentation check function
perform_docs_check() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local repo_type
    
    log_info "Starting documentation check for $repo"
    
    repo_type=$(detect_repo_type "$repo_path")
    log_info "Detected repository type: $repo_type"
    
    local check_results=""
    check_results+="Repository: $repo ($repo_type)\n"
    check_results+="Path: $repo_path\n\n"
    
    # Perform documentation checks
    check_results+="$(check_documentation "$repo_path" "$repo_type")\n"
    
    # Check consistency
    check_results+="$(check_consistency "$repo_path")\n"
    
    # Generate summary
    local status="COMPLETED"
    generate_summary "$TOOL_NAME" "$repo" "$status" "$check_results"
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
    
    local all_results=""
    
    for repo in $(get_repo_list "$REPO"); do
        if [[ $VERBOSE == true ]]; then
            log_info "Processing repository: $repo"
        fi
        
        local repo_results
        repo_results=$(perform_docs_check "$repo")
        all_results+="$repo_results\n\n"
    done
    
    # Format and output results
    format_output "$all_results" "$FORMAT" "$OUTPUT_FILE"
    
    log_success "Documentation check completed"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi