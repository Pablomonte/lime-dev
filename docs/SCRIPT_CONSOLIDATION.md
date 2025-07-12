# Script Consolidation Documentation

This document describes the major script reorganization and consolidation performed to clean up the lime-build development environment.

## Overview

The lime-build repository's scripts/ directory was reorganized from 11 scattered scripts into a clean, hierarchical structure with 3 main entry points and organized subdirectories.

## Before vs After

### Before (11 scattered scripts)
```
scripts/
├── check-setup.sh
├── config-parser.sh  
├── docker-build.sh
├── env-setup.sh
├── librerouteros-wrapper.sh
├── monitor-build.sh
├── setup-environment.sh
├── setup-lime-dev-safe.sh
├── setup-lime-dev.sh
├── update-repos.sh
└── validate-config.sh
```

### After (organized structure)
```
scripts/
├── lime                    # Main interface (unified entry point)
├── setup.sh               # Setup management
├── build.sh               # Build management
├── core/                  # Core functionality (active scripts)
│   ├── check-setup.sh
│   ├── docker-build.sh
│   ├── librerouteros-wrapper.sh
│   └── setup-lime-dev-safe.sh
├── utils/                 # Utility scripts
│   ├── config-parser.sh
│   ├── env-setup.sh
│   └── update-repos.sh
└── legacy/                # Archived/deprecated scripts
    ├── monitor-build.sh
    ├── setup-environment.sh
    ├── setup-lime-dev.sh
    └── validate-config.sh
```

## Key Changes

### 1. Created Unified Interface (`lime`)

A single command interface that handles all common operations:

```bash
# Before (multiple scattered commands)
./scripts/check-setup.sh
./scripts/setup-lime-dev-safe.sh  
./scripts/librerouteros-wrapper.sh librerouter-v1
./scripts/docker-build.sh librerouter-v1
./scripts/update-repos.sh

# After (unified interface)
./scripts/lime check
./scripts/lime setup install
./scripts/lime build
./scripts/lime build docker
./scripts/lime update
```

### 2. Created Management Scripts

**`setup.sh` - Setup Management:**
- Unified entry point for all setup operations
- Supports check, install, install-auto, update, deps, env commands
- Routes to appropriate core/legacy scripts based on safety requirements

**`build.sh` - Build Management:**
- Unified entry point for all build operations
- Supports native/docker methods with various targets
- Handles download-only, shell mode, and cleaning operations

### 3. Organized by Function

**`core/` - Active, maintained scripts:**
- Core functionality that's actively used and maintained
- Direct execution scripts for specific operations
- Safe, well-tested implementations

**`utils/` - Shared utilities:**
- Configuration parsing and environment setup
- Repository management utilities
- Reusable components used by other scripts

**`legacy/` - Archived scripts:**
- Older implementations kept for reference
- Potentially disruptive or redundant scripts
- Not deleted to preserve institutional knowledge

### 4. Improved Docker Integration

Consolidated Docker approach:
- Removed redundant Docker wrapper scripts
- `docker-build.sh` now uses native LibreRouterOS Docker system
- Eliminated conflicting Docker configurations
- Single source of truth: original LibreRouterOS `Dockerfiles/Dockerfile.build`

### 5. Enhanced Safety

Setup safety improvements:
- `setup-lime-dev-safe.sh` as default setup method
- User confirmation for potentially disruptive operations
- Git stashing for uncommitted changes
- Non-destructive environment checking

## Usage Migration

### Old Usage → New Usage

**Environment Setup:**
```bash
# Old
./scripts/setup-lime-dev.sh

# New (safer)
./scripts/lime setup install
# or direct: ./scripts/setup.sh install
```

**Status Checking:**
```bash
# Old
./scripts/check-setup.sh

# New
./scripts/lime check
# or direct: ./scripts/core/check-setup.sh
```

**Building:**
```bash
# Old
./scripts/librerouteros-wrapper.sh librerouter-v1
./scripts/docker-build.sh librerouter-v1

# New  
./scripts/lime build
./scripts/lime build docker
# or direct: ./scripts/build.sh native librerouter-v1
```

**Repository Updates:**
```bash
# Old
./scripts/update-repos.sh

# New
./scripts/lime update
# or direct: ./scripts/utils/update-repos.sh
```

## Benefits

### 1. User Experience
- **Single entry point**: `lime` command for all operations
- **Intuitive commands**: `lime setup install`, `lime build`, `lime check`
- **Consistent interface**: Unified help and error messages
- **Reduced cognitive load**: 3 main commands instead of 11 scripts

### 2. Maintainability
- **Clear organization**: Scripts grouped by function and status
- **Separation of concerns**: Setup, build, utilities clearly separated
- **Legacy preservation**: Old scripts archived, not lost
- **Focused maintenance**: Active scripts in `core/`, deprecated in `legacy/`

### 3. Safety
- **Default safe operations**: Safe setup as default path
- **User confirmation**: Destructive operations require confirmation
- **Fallback options**: Direct script access when needed
- **Environment preservation**: Git stashing and conflict detection

### 4. Development Workflow
- **Faster onboarding**: New developers use simple `lime setup install`
- **Clear documentation**: Each script has defined purpose and location
- **Easier testing**: Isolated functionality in organized structure
- **Better debugging**: Clear script hierarchy for troubleshooting

## Implementation Details

### Path Resolution
All new scripts use intelligent path resolution that works from any directory:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
```

### Environment Integration
Scripts source and use the centralized configuration system:
- `configs/versions.conf` for repository definitions
- `utils/config-parser.sh` for configuration parsing
- `utils/env-setup.sh` for environment variable export

### Backward Compatibility
Direct script execution still works:
```bash
./scripts/core/check-setup.sh           # Direct execution
./scripts/utils/update-repos.sh         # Direct execution
./scripts/legacy/setup-lime-dev.sh      # Legacy script access
```

## Future Considerations

### Potential Improvements
1. **Tab completion**: Shell completion for `lime` command
2. **Configuration management**: Centralized configuration editing
3. **Plugin system**: Extensible command architecture
4. **Monitoring integration**: Build progress and status tracking

### Migration Strategy
1. **Phase 1** (Current): New structure with backward compatibility
2. **Phase 2** (Future): Deprecation warnings for direct legacy script usage
3. **Phase 3** (Future): Remove legacy scripts if unused

### Documentation Updates
- README.md updated with new command examples
- All documentation now references `lime` interface
- Legacy documentation preserved in `legacy/` directory

## Testing

The consolidation has been tested for:
- ✅ Command routing works correctly
- ✅ Path resolution works from any directory  
- ✅ Backward compatibility maintained
- ✅ Environment setup functions properly
- ✅ Build operations execute correctly

## Conclusion

This script consolidation significantly improves the lime-build user experience while maintaining all existing functionality. The new structure is more intuitive, safer, and easier to maintain while preserving institutional knowledge in the legacy archive.