#!/bin/bash

# AI Quality Check Tool
# Comprehensive quality analysis across LibreMesh repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tool-specific configuration
TOOL_NAME="quality-check"
DESCRIPTION="Comprehensive quality analysis"

# Quality metrics configuration
declare -A QUALITY_THRESHOLDS=(
    ["file_size_mb"]=1
    ["line_length"]=120
    ["function_length"]=50
    ["complexity_threshold"]=10
)

# Check code metrics
check_code_metrics() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Analyzing code metrics in $repo_path"
    
    results+="=== Code Metrics Analysis ===\n"
    
    # File count and size analysis
    local total_files
    total_files=$(find "$repo_path" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" | wc -l)
    results+="📁 Total files: $total_files\n"
    
    local source_files
    case "$repo_type" in
        nodejs)
            source_files=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | grep -v node_modules | wc -l)
            ;;
        openwrt|makefile)
            source_files=$(find "$repo_path" -name "*.c" -o -name "*.h" -o -name "*.sh" -o -name "Makefile" | wc -l)
            ;;
        *)
            source_files=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.py" -o -name "*.sh" | wc -l)
            ;;
    esac
    results+="💻 Source files: $source_files\n"
    
    # Repository size
    local repo_size
    repo_size=$(du -sh "$repo_path" 2>/dev/null | cut -f1)
    results+="💾 Repository size: $repo_size\n"
    
    # Line count analysis
    results+="$(check_line_metrics "$repo_path" "$repo_type")\n"
    
    # Complexity analysis
    results+="$(check_complexity "$repo_path" "$repo_type")\n"
    
    echo -e "$results"
}

# Check line-based metrics
check_line_metrics() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Line Metrics ===\n"
    
    local file_patterns
    case "$repo_type" in
        nodejs)
            file_patterns="-name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx'"
            ;;
        openwrt|makefile)
            file_patterns="-name '*.c' -o -name '*.h' -o -name '*.sh'"
            ;;
        *)
            file_patterns="-name '*.c' -o -name '*.h' -o -name '*.py' -o -name '*.sh'"
            ;;
    esac
    
    # Total lines of code
    local total_lines
    total_lines=$(eval "find '$repo_path' $file_patterns" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    results+="📏 Total lines of code: $total_lines\n"
    
    # Average file size
    local file_count
    file_count=$(eval "find '$repo_path' $file_patterns" | wc -l)
    if [[ $file_count -gt 0 ]]; then
        local avg_lines=$((total_lines / file_count))
        results+="📊 Average lines per file: $avg_lines\n"
    fi
    
    # Long line detection
    local long_lines
    long_lines=$(eval "find '$repo_path' $file_patterns" | xargs grep -l ".\{${QUALITY_THRESHOLDS[line_length]},\}" 2>/dev/null | wc -l || echo "0")
    results+="📐 Files with long lines (>${QUALITY_THRESHOLDS[line_length]} chars): $long_lines\n"
    
    # Empty files
    local empty_files
    empty_files=$(eval "find '$repo_path' $file_patterns" | xargs -I {} sh -c '[ ! -s "{}" ] && echo "{}"' | wc -l)
    results+="📄 Empty files: $empty_files\n"
    
    echo -e "$results"
}

# Check code complexity
check_complexity() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Complexity Analysis ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(check_js_complexity "$repo_path")\n"
            ;;
        openwrt|makefile)
            results+="$(check_shell_complexity "$repo_path")\n"
            ;;
        *)
            results+="$(check_generic_complexity "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# JavaScript/TypeScript complexity analysis
check_js_complexity() {
    local repo_path="$1"
    local results=""
    
    # Function count
    local function_count
    function_count=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | \
        xargs grep -h "function\|=>" 2>/dev/null | wc -l || echo "0")
    results+="🔧 Functions/methods: $function_count\n"
    
    # Class count
    local class_count
    class_count=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | \
        xargs grep -h "^class\|export class" 2>/dev/null | wc -l || echo "0")
    results+="🏗️  Classes: $class_count\n"
    
    # Import/require statements
    local import_count
    import_count=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | \
        xargs grep -h "^import\|require(" 2>/dev/null | wc -l || echo "0")
    results+="📦 Import statements: $import_count\n"
    
    # Nested depth estimation (simplified)
    local deep_nesting
    deep_nesting=$(find "$repo_path" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | \
        xargs grep -l "        {.*{.*{" 2>/dev/null | wc -l || echo "0")
    results+="🔄 Files with deep nesting: $deep_nesting\n"
    
    echo -e "$results"
}

# Shell script complexity analysis
check_shell_complexity() {
    local repo_path="$1"
    local results=""
    
    # Function count in shell scripts
    local function_count
    function_count=$(find "$repo_path" -name "*.sh" | xargs grep -h "^[a-zA-Z_][a-zA-Z0-9_]*() {" 2>/dev/null | wc -l || echo "0")
    results+="🔧 Shell functions: $function_count\n"
    
    # Script count
    local script_count
    script_count=$(find "$repo_path" -name "*.sh" | wc -l)
    results+="📜 Shell scripts: $script_count\n"
    
    # Complex conditionals
    local complex_conditionals
    complex_conditionals=$(find "$repo_path" -name "*.sh" | xargs grep -h "if.*&&.*||" 2>/dev/null | wc -l || echo "0")
    results+="❓ Complex conditionals: $complex_conditionals\n"
    
    echo -e "$results"
}

# Generic complexity analysis
check_generic_complexity() {
    local repo_path="$1"
    local results=""
    
    # General complexity indicators
    local nested_blocks
    nested_blocks=$(find "$repo_path" -type f | xargs grep -l "    {.*{" 2>/dev/null | wc -l || echo "0")
    results+="🔄 Files with nested blocks: $nested_blocks\n"
    
    # Comment ratio
    local total_lines
    total_lines=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.py" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "1")
    local comment_lines
    comment_lines=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.py" | xargs grep -h "^\s*#\|^\s*//\|^\s*/\*" 2>/dev/null | wc -l || echo "0")
    
    if [[ $total_lines -gt 0 ]]; then
        local comment_ratio=$((comment_lines * 100 / total_lines))
        results+="💬 Comment ratio: $comment_ratio%\n"
    fi
    
    echo -e "$results"
}

# Check maintainability metrics
check_maintainability() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Maintainability Analysis ===\n"
    
    # TODO/FIXME analysis
    local todo_patterns=("TODO" "FIXME" "HACK" "XXX" "BUG")
    local total_todos=0
    
    for pattern in "${todo_patterns[@]}"; do
        local count
        count=$(rg -i "$pattern" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        total_todos=$((total_todos + count))
        results+="📝 $pattern comments: $count\n"
    done
    
    results+="📋 Total technical debt items: $total_todos\n\n"
    
    # Duplication detection (simplified)
    results+="$(check_duplication "$repo_path" "$repo_type")\n"
    
    # Dependency analysis
    results+="$(check_dependencies "$repo_path" "$repo_type")\n"
    
    echo -e "$results"
}

# Check code duplication
check_duplication() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Duplication Analysis ===\n"
    
    # Simple duplication check using common patterns
    local duplicate_lines
    case "$repo_type" in
        nodejs)
            # Check for duplicate imports
            duplicate_lines=$(find "$repo_path" -name "*.js" -o -name "*.ts" | xargs grep -h "^import" 2>/dev/null | sort | uniq -d | wc -l || echo "0")
            results+="🔄 Duplicate import statements: $duplicate_lines\n"
            ;;
        *)
            # Check for duplicate function signatures (simplified)
            duplicate_lines=$(find "$repo_path" -type f -name "*.c" -o -name "*.h" -o -name "*.sh" | xargs grep -h "^[a-zA-Z_].*(" 2>/dev/null | sort | uniq -d | wc -l || echo "0")
            results+="🔄 Potential duplicate functions: $duplicate_lines\n"
            ;;
    esac
    
    echo -e "$results"
}

# Check dependencies
check_dependencies() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Dependency Analysis ===\n"
    
    case "$repo_type" in
        nodejs)
            if [[ -f "$repo_path/package.json" ]]; then
                local deps
                deps=$(jq -r '.dependencies // {} | keys | length' "$repo_path/package.json" 2>/dev/null || echo "0")
                local dev_deps
                dev_deps=$(jq -r '.devDependencies // {} | keys | length' "$repo_path/package.json" 2>/dev/null || echo "0")
                results+="📦 Runtime dependencies: $deps\n"
                results+="🛠️  Development dependencies: $dev_deps\n"
                results+="📊 Total dependencies: $((deps + dev_deps))\n"
            fi
            ;;
        openwrt)
            # Check for package dependencies in Makefiles
            local pkg_deps
            pkg_deps=$(find "$repo_path" -name "Makefile" | xargs grep -h "DEPENDS:=" 2>/dev/null | wc -l || echo "0")
            results+="📦 Package dependencies: $pkg_deps\n"
            ;;
    esac
    
    echo -e "$results"
}

# Generate quality score
calculate_quality_score() {
    local repo="$1"
    local metrics="$2"
    local score=100
    
    # Deduct points for quality issues
    local todo_count
    todo_count=$(echo "$metrics" | grep "Total technical debt items:" | awk '{print $NF}' || echo "0")
    score=$((score - todo_count))
    
    local long_lines
    long_lines=$(echo "$metrics" | grep "Files with long lines" | awk '{print $NF}' || echo "0")
    score=$((score - long_lines * 2))
    
    local deep_nesting
    deep_nesting=$(echo "$metrics" | grep "Files with deep nesting:" | awk '{print $NF}' || echo "0")
    score=$((score - deep_nesting * 3))
    
    # Ensure score doesn't go below 0
    [[ $score -lt 0 ]] && score=0
    
    echo "Quality Score: $score/100"
}

# Main quality check function
perform_quality_check() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local repo_type
    
    log_info "Starting quality check for $repo"
    
    repo_type=$(detect_repo_type "$repo_path")
    log_info "Detected repository type: $repo_type"
    
    local check_results=""
    check_results+="Repository: $repo ($repo_type)\n"
    check_results+="Path: $repo_path\n\n"
    
    # Perform quality checks
    check_results+="$(check_code_metrics "$repo_path" "$repo_type")\n"
    check_results+="$(check_maintainability "$repo_path" "$repo_type")\n"
    
    # Calculate quality score
    local quality_score
    quality_score=$(calculate_quality_score "$repo" "$check_results")
    check_results+="\n=== Overall Assessment ===\n"
    check_results+="$quality_score\n"
    
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
    
    if ! check_ai_tools; then
        log_warning "Some tools are missing but continuing anyway"
    fi
    
    local all_results=""
    
    for repo in $(get_repo_list "$REPO"); do
        if [[ $VERBOSE == true ]]; then
            log_info "Processing repository: $repo"
        fi
        
        local repo_results
        repo_results=$(perform_quality_check "$repo")
        all_results+="$repo_results\n\n"
    done
    
    # Format and output results
    format_output "$all_results" "$FORMAT" "$OUTPUT_FILE"
    
    log_success "Quality check completed"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi