#!/bin/bash

# AI Security Scan Tool
# Security vulnerability detection across LibreMesh repositories

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Tool-specific configuration
TOOL_NAME="security-scan"
DESCRIPTION="Security vulnerability detection"

# Security patterns to detect
declare -a SECURITY_PATTERNS=(
    "password\s*=\s*['\"][^'\"]+['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "secret\s*=\s*['\"][^'\"]+['\"]"
    "token\s*=\s*['\"][^'\"]+['\"]"
    "private[_-]?key\s*=\s*['\"][^'\"]+['\"]"
    "access[_-]?token\s*=\s*['\"][^'\"]+['\"]"
    "auth[_-]?token\s*=\s*['\"][^'\"]+['\"]"
    "client[_-]?secret\s*=\s*['\"][^'\"]+['\"]"
)

# Dangerous function patterns
declare -a DANGEROUS_FUNCTIONS=(
    "eval\s*\("
    "exec\s*\("
    "system\s*\("
    "shell_exec\s*\("
    "passthru\s*\("
    "popen\s*\("
    "proc_open\s*\("
    "file_get_contents\s*\(\s*\$"
    "fopen\s*\(\s*\$"
    "include\s*\(\s*\$"
    "require\s*\(\s*\$"
)

# Insecure patterns
declare -a INSECURE_PATTERNS=(
    "md5\s*\("
    "sha1\s*\("
    "base64_decode\s*\("
    "unserialize\s*\("
    "http://[^'\"\s]+"
    "ftp://[^'\"\s]+"
    "telnet://[^'\"\s]+"
)

# Check for hardcoded secrets
check_hardcoded_secrets() {
    local repo_path="$1"
    local results=""
    
    log_info "Scanning for hardcoded secrets in $repo_path"
    
    results+="=== Hardcoded Secrets Analysis ===\n"
    
    local total_issues=0
    
    for pattern in "${SECURITY_PATTERNS[@]}"; do
        local matches
        matches=$(rg -i "$pattern" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        if [[ $matches -gt 0 ]]; then
            local pattern_name
            pattern_name=$(echo "$pattern" | sed 's/\\s\*=.*$//' | sed 's/\[_-\]/-/' | sed 's/\\//g')
            results+="🔑 $pattern_name: $matches matches\n"
            total_issues=$((total_issues + matches))
        fi
    done
    
    if [[ $total_issues -eq 0 ]]; then
        results+="✅ No hardcoded secrets detected\n"
    else
        results+="⚠️  Total secret-like patterns: $total_issues\n"
    fi
    
    results+="\n"
    echo -e "$results"
}

# Check for dangerous function usage
check_dangerous_functions() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    log_info "Scanning for dangerous functions in $repo_path"
    
    results+="=== Dangerous Functions Analysis ===\n"
    
    local total_issues=0
    
    for pattern in "${DANGEROUS_FUNCTIONS[@]}"; do
        local matches
        matches=$(rg -i "$pattern" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        if [[ $matches -gt 0 ]]; then
            local func_name
            func_name=$(echo "$pattern" | sed 's/\\s\*.*$//' | sed 's/\\//g')
            results+="⚠️  $func_name: $matches usages\n"
            total_issues=$((total_issues + matches))
        fi
    done
    
    if [[ $total_issues -eq 0 ]]; then
        results+="✅ No dangerous functions detected\n"
    else
        results+="🚨 Total dangerous function calls: $total_issues\n"
    fi
    
    results+="\n"
    echo -e "$results"
}

# Check for insecure patterns
check_insecure_patterns() {
    local repo_path="$1"
    local results=""
    
    log_info "Scanning for insecure patterns in $repo_path"
    
    results+="=== Insecure Patterns Analysis ===\n"
    
    local total_issues=0
    
    for pattern in "${INSECURE_PATTERNS[@]}"; do
        local matches
        matches=$(rg -i "$pattern" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        if [[ $matches -gt 0 ]]; then
            local pattern_name
            pattern_name=$(echo "$pattern" | sed 's/\\s\*.*$//' | sed 's/\\//g' | sed 's/\[.*$//')
            results+="🔒 $pattern_name: $matches occurrences\n"
            total_issues=$((total_issues + matches))
        fi
    done
    
    if [[ $total_issues -eq 0 ]]; then
        results+="✅ No insecure patterns detected\n"
    else
        results+="⚠️  Total insecure patterns: $total_issues\n"
    fi
    
    results+="\n"
    echo -e "$results"
}

# Check file permissions
check_file_permissions() {
    local repo_path="$1"
    local results=""
    
    log_info "Checking file permissions in $repo_path"
    
    results+="=== File Permissions Analysis ===\n"
    
    # Check for executable files that shouldn't be
    local suspicious_executables
    suspicious_executables=$(find "$repo_path" -type f -perm /111 -name "*.txt" -o -name "*.md" -o -name "*.json" 2>/dev/null | wc -l || echo "0")
    
    if [[ $suspicious_executables -gt 0 ]]; then
        results+="⚠️  Suspicious executable files: $suspicious_executables\n"
    else
        results+="✅ No suspicious executable files\n"
    fi
    
    # Check for world-writable files
    local world_writable
    world_writable=$(find "$repo_path" -type f -perm -002 2>/dev/null | wc -l || echo "0")
    
    if [[ $world_writable -gt 0 ]]; then
        results+="🚨 World-writable files: $world_writable\n"
    else
        results+="✅ No world-writable files\n"
    fi
    
    # Check for files with no permissions
    local no_permissions
    no_permissions=$(find "$repo_path" -type f -perm 000 2>/dev/null | wc -l || echo "0")
    
    if [[ $no_permissions -gt 0 ]]; then
        results+="⚠️  Files with no permissions: $no_permissions\n"
    else
        results+="✅ All files have proper permissions\n"
    fi
    
    results+="\n"
    echo -e "$results"
}

# Check for network security issues
check_network_security() {
    local repo_path="$1"
    local results=""
    
    log_info "Checking network security patterns in $repo_path"
    
    results+="=== Network Security Analysis ===\n"
    
    # Check for hardcoded IPs
    local ip_addresses
    ip_addresses=$(rg -E "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    results+="🌐 Hardcoded IP addresses: $ip_addresses\n"
    
    # Check for unencrypted protocols
    local http_urls
    http_urls=$(rg "http://[^'\"\s]+" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    results+="🔓 HTTP URLs (unencrypted): $http_urls\n"
    
    local ftp_urls
    ftp_urls=$(rg "ftp://[^'\"\s]+" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    results+="📁 FTP URLs (unencrypted): $ftp_urls\n"
    
    # Check for default ports
    local default_ports=("22" "23" "21" "80" "443" "3389" "5432" "3306")
    local port_refs=0
    
    for port in "${default_ports[@]}"; do
        local matches
        matches=$(rg ":$port\b" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        port_refs=$((port_refs + matches))
    done
    results+="🔌 Default port references: $port_refs\n"
    
    results+="\n"
    echo -e "$results"
}

# Repository-specific security checks
check_repo_specific_security() {
    local repo_path="$1"
    local repo_type="$2"
    local results=""
    
    results+="=== Repository-Specific Security ===\n"
    
    case "$repo_type" in
        nodejs)
            results+="$(check_nodejs_security "$repo_path")\n"
            ;;
        openwrt)
            results+="$(check_openwrt_security "$repo_path")\n"
            ;;
        *)
            results+="$(check_generic_security "$repo_path")\n"
            ;;
    esac
    
    echo -e "$results"
}

# Node.js specific security checks
check_nodejs_security() {
    local repo_path="$1"
    local results=""
    
    # Check for vulnerable dependencies
    if [[ -f "$repo_path/package.json" ]]; then
        results+="📦 Package.json security:\n"
        
        # Check for known vulnerable packages (simplified check)
        local vulnerable_deps=("lodash" "moment" "jquery" "bootstrap")
        for dep in "${vulnerable_deps[@]}"; do
            if jq -e ".dependencies.\"$dep\"" "$repo_path/package.json" >/dev/null 2>&1; then
                results+="  ⚠️  Potentially outdated dependency: $dep\n"
            fi
        done
        
        # Check for scripts with dangerous commands
        local scripts_with_curl
        scripts_with_curl=$(jq -r '.scripts // {} | to_entries[] | select(.value | contains("curl")) | .key' "$repo_path/package.json" 2>/dev/null | wc -l || echo "0")
        if [[ $scripts_with_curl -gt 0 ]]; then
            results+="  ⚠️  Scripts using curl: $scripts_with_curl\n"
        fi
    fi
    
    # Check for .env files with secrets
    if [[ -f "$repo_path/.env" ]]; then
        results+="🔐 Environment file found - check for secrets\n"
    fi
    
    echo -e "$results"
}

# OpenWrt specific security checks
check_openwrt_security() {
    local repo_path="$1"
    local results=""
    
    # Check for default credentials
    local default_creds
    default_creds=$(rg -i "admin|root|password|123456" "$repo_path" --type-not binary -c 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    results+="🔑 Potential default credentials: $default_creds\n"
    
    # Check for kernel module security
    local kernel_modules
    kernel_modules=$(find "$repo_path" -name "*.ko" | wc -l)
    results+="🐧 Kernel modules: $kernel_modules\n"
    
    # Check for network configuration security
    local network_configs
    network_configs=$(find "$repo_path" -name "*network*" -name "*.conf" | wc -l)
    results+="🌐 Network config files: $network_configs\n"
    
    echo -e "$results"
}

# Generic security checks
check_generic_security() {
    local repo_path="$1"
    local results=""
    
    # Check for backup files
    local backup_files
    backup_files=$(find "$repo_path" -name "*.bak" -o -name "*.backup" -o -name "*~" | wc -l)
    results+="💾 Backup files: $backup_files\n"
    
    # Check for temporary files
    local temp_files
    temp_files=$(find "$repo_path" -name "*.tmp" -o -name "*.temp" | wc -l)
    results+="🗂️  Temporary files: $temp_files\n"
    
    echo -e "$results"
}

# Generate security risk assessment
assess_security_risk() {
    local repo="$1"
    local scan_results="$2"
    local risk_score=0
    
    # Calculate risk based on findings
    local secrets
    secrets=$(echo "$scan_results" | grep "Total secret-like patterns:" | awk '{print $NF}' || echo "0")
    risk_score=$((risk_score + secrets * 10))
    
    local dangerous_funcs
    dangerous_funcs=$(echo "$scan_results" | grep "Total dangerous function calls:" | awk '{print $NF}' || echo "0")
    risk_score=$((risk_score + dangerous_funcs * 5))
    
    local insecure_patterns
    insecure_patterns=$(echo "$scan_results" | grep "Total insecure patterns:" | awk '{print $NF}' || echo "0")
    risk_score=$((risk_score + insecure_patterns * 3))
    
    # Determine risk level
    local risk_level
    if [[ $risk_score -eq 0 ]]; then
        risk_level="🟢 LOW"
    elif [[ $risk_score -lt 20 ]]; then
        risk_level="🟡 MEDIUM"
    elif [[ $risk_score -lt 50 ]]; then
        risk_level="🟠 HIGH"
    else
        risk_level="🔴 CRITICAL"
    fi
    
    echo "Security Risk Level: $risk_level (Score: $risk_score)"
}

# Main security scan function
perform_security_scan() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local repo_type
    
    log_info "Starting security scan for $repo"
    
    repo_type=$(detect_repo_type "$repo_path")
    log_info "Detected repository type: $repo_type"
    
    local scan_results=""
    scan_results+="Repository: $repo ($repo_type)\n"
    scan_results+="Path: $repo_path\n\n"
    
    # Perform security checks
    scan_results+="$(check_hardcoded_secrets "$repo_path")\n"
    scan_results+="$(check_dangerous_functions "$repo_path" "$repo_type")\n"
    scan_results+="$(check_insecure_patterns "$repo_path")\n"
    scan_results+="$(check_file_permissions "$repo_path")\n"
    scan_results+="$(check_network_security "$repo_path")\n"
    scan_results+="$(check_repo_specific_security "$repo_path" "$repo_type")\n"
    
    # Assess overall risk
    local risk_assessment
    risk_assessment=$(assess_security_risk "$repo" "$scan_results")
    scan_results+="\n=== Security Assessment ===\n"
    scan_results+="$risk_assessment\n"
    
    # Generate summary
    local status="COMPLETED"
    generate_summary "$TOOL_NAME" "$repo" "$status" "$scan_results"
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
        repo_results=$(perform_security_scan "$repo")
        all_results+="$repo_results\n\n"
    done
    
    # Format and output results
    format_output "$all_results" "$FORMAT" "$OUTPUT_FILE"
    
    log_success "Security scan completed"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi