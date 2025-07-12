#!/bin/bash

# AI Test Validation Tool
# Test coverage and quality validation across LibreMesh repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tool-specific configuration
TOOL_NAME="test-validation"
DESCRIPTION="Test coverage and quality validation"

# Test quality thresholds
declare -A TEST_THRESHOLDS=(
    ["coverage_target"]=70
    ["min_assertions"]=1
    ["max_test_duration"]=30
)

# Check test structure
check_test_structure() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Analyzing test structure in $repo_path"
    
    results+="=== Test Structure Analysis ===\n"
    
    # Find test directories
    local test_dirs=()
    if [[ -d "$repo_path/test" ]]; then
        test_dirs+=("test")
    fi
    if [[ -d "$repo_path/tests" ]]; then
        test_dirs+=("tests")
    fi
    if [[ -d "$repo_path/spec" ]]; then
        test_dirs+=("spec")
    fi
    if [[ -d "$repo_path/src/__tests__" ]]; then
        test_dirs+=("src/__tests__")
    fi
    
    results+="📁 Test directories: ${#test_dirs[@]}\n"
    for dir in "${test_dirs[@]}"; do
        results+="   - $dir/\n"
    done
    
    # Count test files by type
    case "$repo_type" in
        nodejs)
            results+="$(count_js_test_files "$repo_path")\n"
            ;;
        *)
            results+="$(count_generic_test_files "$repo_path")\n"
            ;;
    esac
    
    results+="\n"
    echo -e "$results"
}

# Count JavaScript/TypeScript test files
count_js_test_files() {
    local repo_path="$1"
    local results=""
    
    # Test file patterns for JavaScript projects
    local test_patterns=(
        "*.test.js"
        "*.test.ts"
        "*.spec.js"
        "*.spec.ts"
        "*.test.jsx"
        "*.test.tsx"
    )
    
    local total_test_files=0
    for pattern in "${test_patterns[@]}"; do
        local count
        count=$(find "$repo_path" -name "$pattern" | wc -l)
        if [[ $count -gt 0 ]]; then
            results+="🧪 $pattern files: $count\n"
            total_test_files=$((total_test_files + count))
        fi
    done
    
    results+="📊 Total test files: $total_test_files\n"
    
    # Test configuration files
    local config_files=()
    [[ -f "$repo_path/jest.config.js" ]] && config_files+=("jest.config.js")
    [[ -f "$repo_path/jest.config.json" ]] && config_files+=("jest.config.json")
    [[ -f "$repo_path/vitest.config.js" ]] && config_files+=("vitest.config.js")
    [[ -f "$repo_path/karma.conf.js" ]] && config_files+=("karma.conf.js")
    [[ -f "$repo_path/mocha.opts" ]] && config_files+=("mocha.opts")
    
    results+="⚙️  Test config files: ${#config_files[@]}\n"
    for config in "${config_files[@]}"; do
        results+="   - $config\n"
    done
    
    echo -e "$results"
}

# Count generic test files
count_generic_test_files() {
    local repo_path="$1"
    local results=""
    
    # Shell test files
    local shell_tests
    shell_tests=$(find "$repo_path" -name "*test*.sh" -o -name "*spec*.sh" | wc -l)
    results+="🐚 Shell test files: $shell_tests\n"
    
    # C/C++ test files
    local c_tests
    c_tests=$(find "$repo_path" -name "*test*.c" -o -name "*test*.cpp" | wc -l)
    results+="⚙️  C/C++ test files: $c_tests\n"
    
    # Python test files
    local py_tests
    py_tests=$(find "$repo_path" -name "test_*.py" -o -name "*_test.py" | wc -l)
    results+="🐍 Python test files: $py_tests\n"
    
    # Makefile test targets
    if [[ -f "$repo_path/Makefile" ]]; then
        local make_test_targets
        make_test_targets=$(grep -c "^test\|^check:" "$repo_path/Makefile" 2>/dev/null || echo "0")
        results+="🔨 Makefile test targets: $make_test_targets\n"
    fi
    
    echo -e "$results"
}

# Analyze test quality
analyze_test_quality() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Analyzing test quality in $repo_path"
    
    results+="=== Test Quality Analysis ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(analyze_js_test_quality "$repo_path")\n"
            ;;
        *)
            results+="$(analyze_generic_test_quality "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# Analyze JavaScript test quality
analyze_js_test_quality() {
    local repo_path="$1"
    local results=""
    
    # Find all JavaScript test files
    local test_files
    test_files=$(find "$repo_path" -name "*.test.js" -o -name "*.test.ts" -o -name "*.spec.js" -o -name "*.spec.ts")
    
    if [[ -z "$test_files" ]]; then
        results+="⚠️  No JavaScript test files found\n"
        echo -e "$results"
        return
    fi
    
    # Analyze test content
    local total_tests=0
    local total_assertions=0
    local async_tests=0
    local mocked_tests=0
    
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            # Count test cases
            local test_cases
            test_cases=$(grep -c "it(\|test(\|describe(" "$file" 2>/dev/null || echo "0")
            total_tests=$((total_tests + test_cases))
            
            # Count assertions
            local assertions
            assertions=$(grep -c "expect(\|assert\|should" "$file" 2>/dev/null || echo "0")
            total_assertions=$((total_assertions + assertions))
            
            # Count async tests
            local async_count
            async_count=$(grep -c "async\|await\|Promise\|done(" "$file" 2>/dev/null || echo "0")
            [[ $async_count -gt 0 ]] && async_tests=$((async_tests + 1))
            
            # Count mocked tests
            local mock_count
            mock_count=$(grep -c "mock\|spy\|stub\|fake" "$file" 2>/dev/null || echo "0")
            [[ $mock_count -gt 0 ]] && mocked_tests=$((mocked_tests + 1))
        fi
    done <<< "$test_files"
    
    results+="🧪 Total test cases: $total_tests\n"
    results+="✅ Total assertions: $total_assertions\n"
    results+="⏱️  Files with async tests: $async_tests\n"
    results+="🎭 Files with mocks/spies: $mocked_tests\n"
    
    # Calculate assertion ratio
    if [[ $total_tests -gt 0 ]]; then
        local assertion_ratio=$((total_assertions * 100 / total_tests))
        results+="📊 Assertions per test: $assertion_ratio%\n"
        
        if [[ $assertion_ratio -ge 100 ]]; then
            results+="🟢 Test assertion quality: Excellent\n"
        elif [[ $assertion_ratio -ge 50 ]]; then
            results+="🟡 Test assertion quality: Good\n"
        else
            results+="🔴 Test assertion quality: Needs Improvement\n"
        fi
    fi
    
    echo -e "$results"
}

# Analyze generic test quality
analyze_generic_test_quality() {
    local repo_path="$1"
    local results=""
    
    # Check for test execution scripts
    local test_scripts
    test_scripts=$(find "$repo_path" -name "*test*.sh" -executable | wc -l)
    results+="🔧 Executable test scripts: $test_scripts\n"
    
    # Check for test documentation
    local test_docs
    test_docs=$(find "$repo_path" -name "*TEST*" -o -name "*test*.md" | wc -l)
    results+="📚 Test documentation files: $test_docs\n"
    
    # Check for CI configuration
    local ci_configs=()
    [[ -f "$repo_path/.github/workflows/test.yml" ]] && ci_configs+=(".github/workflows/test.yml")
    [[ -f "$repo_path/.gitlab-ci.yml" ]] && ci_configs+=(".gitlab-ci.yml")
    [[ -f "$repo_path/.travis.yml" ]] && ci_configs+=(".travis.yml")
    [[ -f "$repo_path/Jenkinsfile" ]] && ci_configs+=("Jenkinsfile")
    
    results+="🔄 CI configuration files: ${#ci_configs[@]}\n"
    
    echo -e "$results"
}

# Check test coverage
check_test_coverage() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Checking test coverage in $repo_path"
    
    results+="=== Test Coverage Analysis ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(check_js_coverage "$repo_path")\n"
            ;;
        *)
            results+="$(check_generic_coverage "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# Check JavaScript test coverage
check_js_coverage() {
    local repo_path="$1"
    local results=""
    
    # Check for coverage configuration
    local coverage_configs=()
    [[ -f "$repo_path/.nycrc" ]] && coverage_configs+=(".nycrc")
    [[ -f "$repo_path/nyc.config.js" ]] && coverage_configs+=("nyc.config.js")
    [[ -f "$repo_path/coverage.json" ]] && coverage_configs+=("coverage.json")
    
    results+="📊 Coverage config files: ${#coverage_configs[@]}\n"
    
    # Check for coverage directories
    if [[ -d "$repo_path/coverage" ]]; then
        results+="📁 Coverage directory found\n"
        
        # Try to extract coverage information
        if [[ -f "$repo_path/coverage/lcov-report/index.html" ]]; then
            results+="📈 LCOV coverage report available\n"
        fi
        
        if [[ -f "$repo_path/coverage/coverage-summary.json" ]]; then
            results+="📋 Coverage summary available\n"
        fi
    else
        results+="⚠️  No coverage directory found\n"
    fi
    
    # Check package.json for coverage scripts
    if [[ -f "$repo_path/package.json" ]]; then
        local coverage_scripts
        coverage_scripts=$(jq -r '.scripts // {} | to_entries[] | select(.value | contains("coverage")) | .key' "$repo_path/package.json" 2>/dev/null | wc -l || echo "0")
        results+="🔧 Coverage scripts in package.json: $coverage_scripts\n"
    fi
    
    echo -e "$results"
}

# Check generic test coverage
check_generic_coverage() {
    local repo_path="$1"
    local results=""
    
    # Check for common coverage tools
    local coverage_files=()
    [[ -f "$repo_path/.coveragerc" ]] && coverage_files+=(".coveragerc")
    [[ -f "$repo_path/coverage.xml" ]] && coverage_files+=("coverage.xml")
    [[ -f "$repo_path/gcov.info" ]] && coverage_files+=("gcov.info")
    
    results+="📊 Coverage files: ${#coverage_files[@]}\n"
    
    # Check for coverage directories
    if [[ -d "$repo_path/htmlcov" ]]; then
        results+="📁 Python coverage directory found\n"
    fi
    
    echo -e "$results"
}

# Validate test execution
validate_test_execution() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Validating test execution in $repo_path"
    
    results+="=== Test Execution Validation ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(validate_js_test_execution "$repo_path")\n"
            ;;
        *)
            results+="$(validate_generic_test_execution "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# Validate JavaScript test execution
validate_js_test_execution() {
    local repo_path="$1"
    local results=""
    
    # Check package.json for test scripts
    if [[ -f "$repo_path/package.json" ]]; then
        local test_script
        test_script=$(jq -r '.scripts.test // empty' "$repo_path/package.json" 2>/dev/null)
        
        if [[ -n "$test_script" && "$test_script" != "null" ]]; then
            results+="✅ Test script found: $test_script\n"
            
            # Check for different test types
            if [[ "$test_script" == *"jest"* ]]; then
                results+="🃏 Using Jest testing framework\n"
            elif [[ "$test_script" == *"mocha"* ]]; then
                results+="☕ Using Mocha testing framework\n"
            elif [[ "$test_script" == *"vitest"* ]]; then
                results+="⚡ Using Vitest testing framework\n"
            elif [[ "$test_script" == *"ava"* ]]; then
                results+="🚀 Using AVA testing framework\n"
            else
                results+="❓ Custom test command\n"
            fi
        else
            results+="⚠️  No test script found in package.json\n"
        fi
        
        # Check for other test-related scripts
        local test_scripts
        test_scripts=$(jq -r '.scripts // {} | to_entries[] | select(.key | contains("test")) | .key' "$repo_path/package.json" 2>/dev/null | wc -l || echo "0")
        results+="🔧 Test-related scripts: $test_scripts\n"
    fi
    
    echo -e "$results"
}

# Validate generic test execution
validate_generic_test_execution() {
    local repo_path="$1"
    local results=""
    
    # Check Makefile for test targets
    if [[ -f "$repo_path/Makefile" ]]; then
        local test_targets
        test_targets=$(grep -c "^test\|^check:" "$repo_path/Makefile" 2>/dev/null || echo "0")
        results+="🔨 Makefile test targets: $test_targets\n"
        
        if [[ $test_targets -gt 0 ]]; then
            results+="✅ Test targets found in Makefile\n"
        fi
    fi
    
    # Check for executable test files
    local executable_tests
    executable_tests=$(find "$repo_path" -name "*test*" -executable -type f | wc -l)
    results+="🏃 Executable test files: $executable_tests\n"
    
    echo -e "$results"
}

# Generate test quality score
calculate_test_score() {
    local repo="$1"
    local validation_results="$2"
    local score=0
    local max_score=100
    
    # Extract metrics from results
    local test_files
    test_files=$(echo "$validation_results" | grep "Total test files:" | awk '{print $NF}' || echo "0")
    
    local test_cases
    test_cases=$(echo "$validation_results" | grep "Total test cases:" | awk '{print $NF}' || echo "0")
    
    local assertions
    assertions=$(echo "$validation_results" | grep "Total assertions:" | awk '{print $NF}' || echo "0")
    
    # Calculate score components
    [[ $test_files -gt 0 ]] && score=$((score + 20))
    [[ $test_cases -gt 0 ]] && score=$((score + 30))
    [[ $assertions -gt 0 ]] && score=$((score + 25))
    
    # Check for coverage
    if echo "$validation_results" | grep -q "Coverage"; then
        score=$((score + 15))
    fi
    
    # Check for CI integration
    if echo "$validation_results" | grep -q "CI configuration files: [1-9]"; then
        score=$((score + 10))
    fi
    
    echo "Test Quality Score: $score/$max_score"
}

# Main test validation function
perform_test_validation() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local repo_type
    
    log_info "Starting test validation for $repo"
    
    repo_type=$(detect_repo_type "$repo_path")
    log_info "Detected repository type: $repo_type"
    
    local validation_results=""
    validation_results+="Repository: $repo ($repo_type)\n"
    validation_results+="Path: $repo_path\n\n"
    
    # Perform test validation
    validation_results+="$(check_test_structure "$repo_path" "$repo_type")\n"
    validation_results+="$(analyze_test_quality "$repo_path" "$repo_type")\n"
    validation_results+="$(check_test_coverage "$repo_path" "$repo_type")\n"
    validation_results+="$(validate_test_execution "$repo_path" "$repo_type")\n"
    
    # Calculate test score
    local test_score
    test_score=$(calculate_test_score "$repo" "$validation_results")
    validation_results+="\n=== Test Assessment ===\n"
    validation_results+="$test_score\n"
    
    # Generate summary
    local status="COMPLETED"
    generate_summary "$TOOL_NAME" "$repo" "$status" "$validation_results"
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
        repo_results=$(perform_test_validation "$repo")
        all_results+="$repo_results\n\n"
    done
    
    # Format and output results
    format_output "$all_results" "$FORMAT" "$OUTPUT_FILE"
    
    log_success "Test validation completed"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi