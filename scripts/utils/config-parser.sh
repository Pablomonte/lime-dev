#!/usr/bin/env bash
#
# Configuration Parser for Lime-Build
# Utility functions to read and parse versions.conf
#

CONFIG_FILE="${CONFIG_FILE:-$(dirname "$0")/../configs/versions.conf}"

# Parse a value from a specific section
# Usage: get_config_value section key
get_config_value() {
    local section="$1"
    local key="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Configuration file not found: $CONFIG_FILE" >&2
        return 1
    fi
    
    # Find the section and extract the value
    awk -v section="[$section]" -v key="$key" '
        $0 == section { in_section = 1; next }
        /^\[/ && in_section { in_section = 0 }
        in_section && $0 ~ "^" key "=" {
            sub("^" key "=", "")
            print
            exit
        }
    ' "$CONFIG_FILE"
}

# Get all keys from a section
# Usage: get_section_keys section
get_section_keys() {
    local section="$1"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Configuration file not found: $CONFIG_FILE" >&2
        return 1
    fi
    
    awk -v section="[$section]" '
        $0 == section { in_section = 1; next }
        /^\[/ && in_section { in_section = 0 }
        in_section && /^[^#].*=/ {
            sub("=.*", "")
            print
        }
    ' "$CONFIG_FILE"
}

# Check if running in release mode
is_release_mode() {
    [[ "${LIME_RELEASE_MODE:-false}" == "true" ]]
}

# Get repository configuration with release override support
# Usage: get_repo_config repo_name
get_repo_config() {
    local repo_name="$1"
    local section="repositories"
    local key="$repo_name"
    
    # Check for release overrides
    if is_release_mode; then
        local release_key="${repo_name}_release"
        local release_config=$(get_config_value "release_overrides" "$release_key")
        if [[ -n "$release_config" ]]; then
            echo "$release_config"
            return 0
        fi
    fi
    
    # Fall back to standard repository config
    get_config_value "$section" "$key"
}

# Export functions for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced
    export -f get_config_value
    export -f get_section_keys
    export -f is_release_mode
    export -f get_repo_config
fi

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        "get")
            get_config_value "$2" "$3"
            ;;
        "keys")
            get_section_keys "$2"
            ;;
        "repo")
            get_repo_config "$2"
            ;;
        "release")
            if is_release_mode; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "help")
            echo "Configuration Parser for Lime-Build"
            echo ""
            echo "Usage:"
            echo "  $0 get <section> <key>    - Get value from section"
            echo "  $0 keys <section>         - List keys in section"
            echo "  $0 repo <repo_name>       - Get repository config"
            echo "  $0 release                - Check if in release mode"
            echo ""
            echo "Environment:"
            echo "  CONFIG_FILE=${CONFIG_FILE}"
            echo "  LIME_RELEASE_MODE=${LIME_RELEASE_MODE:-false}"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
fi