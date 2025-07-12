# CLAUDE.md - lime-dev Development Environment

## Repository Purpose

This repository provides a development environment for LibreMesh ecosystem projects, including lime-app, lime-packages, and LibreRouterOS. It includes build automation, code analysis tools, environment verification, and upstream contribution workflows.

## Development Environment Features

This environment addresses common LibreMesh development challenges:

1. **Build System Integration** - Native and Docker-based firmware building
2. **Development Tools** - Code analysis, environment verification, dependency management
3. **QEMU Integration** - Network simulation for lime-app development
4. **Repository Management** - Coordinated setup and updates for multiple repositories
5. **Upstream Workflows** - Git automation for contributing to LibreMesh projects

## Key Components

### Main Setup Script (`setup-lime-dev.sh`)
- Platform detection (Ubuntu/Debian, RHEL/CentOS, Arch Linux)
- Dependency installation (QEMU, Node.js, build tools, network utilities)
- Repository cloning (lime-app, lime-packages, openwrt)
- System configuration (KVM groups, kernel modules, network bridges)
- Development environment setup

### Development Helper (`dev.sh`)
Simple command interface for daily development:
- `./dev.sh start` - Start QEMU mesh router
- `./dev.sh deploy` - Deploy lime-app changes
- `./dev.sh stop` - Stop QEMU environment
- `./dev.sh status` - Check QEMU status
- `./dev.sh configs` - Show available configurations

### Integrated QEMU Configuration
Built on the existing qemu-manager.sh system with:
- Automatic image detection (LibreMesh/LibreRouterOS)
- Image-specific network configuration
- Custom boot parameters for different kernels
- TAP interface management and cleanup

## Solved Issues

### LibreRouterOS Kernel Boot Problem
**Issue**: LibreRouterOS 24.10.1 with kernel 6.6.86 failed to boot in QEMU
**Root Cause**: Newer kernels require explicit `rdinit=/sbin/init` boot parameter
**Solution**: Custom QEMU launcher with proper boot parameters
- Created `qemu_dev_start_librerouteros` with correct parameters
- Updated qemu-manager.sh to detect image type and use appropriate launcher

### Developer Onboarding Complexity
**Issue**: Setting up LibreMesh development environment required manual configuration
**Solution**: Single-script automated setup
- Handles dependency installation across multiple platforms
- Configures system requirements (KVM, network bridges)
- Sets up all repositories and build tools
- Creates simple development workflow

### QEMU Network Configuration
**Issue**: TAP interface creation failures causing silent QEMU startup problems
**Solution**: Pre-creation of required network interfaces
- Creates lime_tap00_1 and lime_tap00_2 before QEMU start
- Proper cleanup on QEMU stop
- Bridge interface management

## Development Workflow

### Initial Setup
```bash
git clone <lime-dev-repo>
cd lime-dev
./setup-lime-dev.sh
```

### Daily Development
```bash
./dev.sh start     # Start QEMU mesh router
# Edit code in lime-app/src/...
./dev.sh deploy    # Deploy changes to QEMU
# Test at http://10.13.0.1/app/
./dev.sh stop      # Stop when done
```

### Configuration Options
- **LibreMesh 23.05.5**: Stable mesh networking (default)
- **LibreRouterOS 24.10.1**: Latest features with kernel 6.6.86
- Auto-detection based on available images in lime-packages/build/

## Technical Details

### Supported Platforms
- **Ubuntu/Debian**: apt-get package installation
- **RHEL/CentOS/Fedora**: yum/dnf package installation  
- **Arch Linux**: pacman package installation
- **macOS**: Homebrew support (limited QEMU performance)

### System Requirements
- 4GB RAM minimum (8GB recommended)
- 5GB disk space minimum
- Linux system with KVM support preferred
- Sudo access for package installation

### Network Configuration
- Bridge interface: lime_br0 (10.13.0.2/16)
- QEMU guest IP: 10.13.0.1
- TAP interfaces: lime_tap00_0, lime_tap00_1, lime_tap00_2
- Console access: `sudo screen -r libremesh`

## Repository Structure

```bash
lime-dev/
├── README.md                    # User documentation
├── CLAUDE.md                    # This file - session knowledge
├── CHANGELOG.md                 # Version history and updates
├── LICENSE                      # Repository license
├── scripts/                     # Build and utility scripts
│   ├── build.sh                # Main build script
│   ├── setup.sh               # Setup script
│   ├── lime                    # Lime CLI wrapper
│   ├── core/                   # Core functionality scripts
│   │   ├── check-setup.sh     # Setup verification
│   │   ├── docker-build.sh    # Docker build management
│   │   ├── librerouteros-wrapper.sh  # LibreRouterOS specific
│   │   └── setup-lime-dev-safe.sh    # Safe dev setup
│   ├── legacy/                 # Legacy scripts (deprecated)
│   └── utils/                  # Utility scripts
│       ├── config-parser.sh    # Configuration parsing
│       ├── env-setup.sh       # Environment setup
│       └── update-repos.sh    # Repository updates
├── configs/                     # Configuration files
│   ├── example_config_librerouter  # LibreRouter config
│   ├── example_config_x86_64      # x86_64 config
│   └── versions.conf          # Version definitions
├── docs/                        # Documentation
│   ├── ARCHITECTURE.md         # System architecture
│   ├── CONTRIBUTING.md         # Contribution guide
│   ├── DEVELOPMENT.md          # Development guide
│   ├── INFRASTRUCTURE_REPLICATION.md  # Infrastructure docs
│   ├── SCRIPT_CONSOLIDATION.md       # Script organization
│   └── TROUBLESHOOTING.md     # Common issues
├── repos/                       # Managed repositories
│   ├── lime-app/               # LibreMesh web interface
│   ├── lime-packages/          # LibreMesh packages + QEMU tools
│   ├── librerouteros/          # LibreRouterOS source
│   └── kconfig-utils/          # Kernel configuration utilities
├── cache/                       # Build cache directory
├── logs/                        # Build logs
└── tests/                       # Test scripts
```

## Current Scripts Guide

### Main Scripts

#### `scripts/lime` - Main CLI Interface
The central command-line interface for all lime-dev operations. This wrapper script provides a unified interface to all functionality.

**Usage:**
```bash
./scripts/lime build [config]     # Build firmware images
./scripts/lime setup             # Initialize development environment
./scripts/lime update            # Update all repositories
./scripts/lime clean             # Clean build artifacts
```

#### `scripts/build.sh` - Build Orchestrator
Manages the complete build process for LibreMesh and LibreRouterOS firmware images.

**Key Features:**
- Auto-detects build type from configuration
- Manages Docker containers for isolated builds
- Handles dependency resolution
- Supports both local and Docker-based builds

**Usage:**
```bash
./scripts/build.sh configs/example_config_x86_64
./scripts/build.sh configs/example_config_librerouter
```

#### `scripts/setup.sh` - Environment Setup
Initializes the complete development environment, including:
- Cloning required repositories
- Setting up build dependencies
- Configuring system requirements
- Creating necessary directories

**Usage:**
```bash
./scripts/setup.sh              # Full setup
./scripts/setup.sh --update     # Update existing setup
```

### Core Scripts (`scripts/core/`)

#### `check-setup.sh` - Setup Verification
Validates that the development environment is correctly configured:
- Checks for required tools
- Verifies repository structure
- Tests Docker availability
- Confirms network configuration

**Usage:**
```bash
./scripts/core/check-setup.sh   # Run all checks
```

#### `docker-build.sh` - Docker Build Management
Handles Docker-based builds for consistent, reproducible firmware compilation:
- Creates isolated build environments
- Manages build containers lifecycle
- Handles volume mounting for source/output
- Supports multiple architectures

**Usage:**
```bash
# Called automatically by build.sh, but can be used directly:
./scripts/core/docker-build.sh --config configs/example_config_x86_64
```

#### `librerouteros-wrapper.sh` - LibreRouterOS Integration
Special wrapper for LibreRouterOS builds that handles:
- Kernel 6.6.86 specific configurations
- Boot parameter management
- Custom patches application
- QEMU compatibility fixes

**Usage:**
```bash
# Typically called by build system:
./scripts/core/librerouteros-wrapper.sh prepare
./scripts/core/librerouteros-wrapper.sh build
```

#### `setup-lime-dev-safe.sh` - Safe Development Setup
A safer version of the setup script that:
- Performs non-destructive operations only
- Backs up existing configurations
- Provides rollback capabilities
- Suitable for existing development environments

**Usage:**
```bash
./scripts/core/setup-lime-dev-safe.sh
```

### Utility Scripts (`scripts/utils/`)

#### `config-parser.sh` - Configuration Parser
Parses and validates build configuration files:
- Extracts build parameters
- Validates configuration syntax
- Resolves version dependencies
- Handles environment variables

**Usage:**
```bash
source ./scripts/utils/config-parser.sh
parse_config "configs/example_config_x86_64"
```

#### `env-setup.sh` - Environment Configuration
Sets up shell environment for lime-dev operations:
- Exports necessary environment variables
- Configures PATH additions
- Sets up build flags
- Manages cross-compilation settings

**Usage:**
```bash
source ./scripts/utils/env-setup.sh
```

#### `update-repos.sh` - Repository Updates
Manages updates for all managed repositories:
- Pulls latest changes from upstream
- Handles merge conflicts
- Updates submodules
- Synchronizes feed definitions

**Usage:**
```bash
./scripts/utils/update-repos.sh          # Update all repos
./scripts/utils/update-repos.sh lime-app # Update specific repo
```

### Legacy Scripts (`scripts/legacy/`)

These scripts are preserved for backward compatibility but should not be used for new development:
- `monitor-build.sh` - Old build monitoring (replaced by build.sh)
- `setup-environment.sh` - Old setup script (replaced by setup.sh)
- `setup-lime-dev.sh` - Original development setup (superseded)
- `validate-config.sh` - Old config validation (integrated into parser)

## Script Workflows

### Initial Setup Workflow
```bash
# 1. Clone the repository
git clone https://github.com/your-org/lime-dev
cd lime-dev

# 2. Run setup
./scripts/setup.sh

# 3. Verify setup
./scripts/core/check-setup.sh

# 4. Build your first image
./scripts/build.sh configs/example_config_x86_64
```

### Development Workflow
```bash
# 1. Update repositories
./scripts/lime update

# 2. Make changes in repos/lime-app or repos/lime-packages

# 3. Build with your changes
./scripts/lime build configs/example_config_x86_64

# 4. Test in QEMU (if using lime-app development)
cd repos/lime-app
./dev.sh start
./dev.sh deploy
```

### Docker Build Workflow
```bash
# 1. Ensure Docker is running
docker info

# 2. Build using Docker (automatic with build.sh)
./scripts/build.sh configs/example_config_librerouter

# 3. Find output in cache/
ls -la cache/
```

### Configuration Management
```bash
# 1. Copy example config
cp configs/example_config_x86_64 configs/my_custom_config

# 2. Edit configuration
vim configs/my_custom_config

# 3. Validate configuration
./scripts/lime build --validate configs/my_custom_config

# 4. Build with custom config
./scripts/lime build configs/my_custom_config
```

## Common Use Cases and Examples

### Building for Different Targets

#### Build for x86_64 (Virtual Machines/Testing)
```bash
./scripts/lime build configs/example_config_x86_64
# Output: cache/openwrt-x86-64-generic-squashfs-combined.img.gz
```

#### Build for LibreRouter Hardware
```bash
./scripts/lime build configs/example_config_librerouter
# Output: cache/openwrt-ath79-generic-librerouter-v1-squashfs-sysupgrade.bin
```

#### Custom Build with Modified Packages
```bash
# 1. Edit package selections
vim configs/my_custom_config
# Add: CONFIG_PACKAGE_lime-proto-bmx7=y
# Remove: # CONFIG_PACKAGE_lime-proto-batman-adv is not set

# 2. Build
./scripts/lime build configs/my_custom_config
```

### Development Scenarios

#### Working on lime-app UI
```bash
# 1. Setup development environment
./scripts/setup.sh

# 2. Start QEMU with LibreMesh
cd repos/lime-app
./dev.sh start

# 3. Make UI changes
vim src/components/app.tsx

# 4. Deploy changes live
./dev.sh deploy

# 5. Access at http://10.13.0.1/app/
```

#### Testing LibreRouterOS Changes
```bash
# 1. Make kernel config changes
cd repos/librerouteros
make menuconfig

# 2. Build new image
cd ../../
./scripts/lime build configs/example_config_librerouter

# 3. Test in QEMU
cd repos/lime-app
# Ensure LibreRouterOS image is in lime-packages/build/
./scripts/qemu-manager.sh start librerouteros
```

#### Debugging Build Failures
```bash
# 1. Enable verbose output
export V=s

# 2. Run build with logging
./scripts/build.sh configs/example_config_x86_64 2>&1 | tee logs/build-$(date +%Y%m%d-%H%M%S).log

# 3. Check specific package build
cd repos/librerouteros
make package/lime-system/compile V=s
```

### Maintenance Tasks

#### Update All Repositories
```bash
# Update to latest upstream
./scripts/lime update

# Update specific repository
./scripts/utils/update-repos.sh lime-packages
```

#### Clean Build Environment
```bash
# Clean all build artifacts
./scripts/lime clean

# Clean specific build
cd repos/librerouteros
make clean

# Deep clean (removes toolchain)
cd repos/librerouteros
make distclean
```

#### Backup Configuration
```bash
# Backup all custom configs
tar -czf lime-configs-backup.tar.gz configs/

# Backup specific build state
cp -r repos/librerouteros/.config configs/saved_librerouteros_config
```

### Troubleshooting Common Issues

#### Build Fails with Missing Dependencies
```bash
# Check and install dependencies
./scripts/core/check-setup.sh

# Manual dependency installation (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install build-essential git libncurses5-dev zlib1g-dev \
  gawk gettext libssl-dev xsltproc rsync wget unzip python3
```

#### QEMU Network Issues
```bash
# Reset network configuration
sudo ip link delete lime_br0 2>/dev/null || true
sudo ./scripts/core/setup-lime-dev-safe.sh --network-only

# Verify network
ip addr show lime_br0
```

#### Docker Build Problems
```bash
# Check Docker status
docker info

# Clean Docker resources
docker system prune -a

# Rebuild without cache
./scripts/core/docker-build.sh --no-cache --config configs/example_config_x86_64
```

### Advanced Usage

#### Parallel Builds
```bash
# Use all CPU cores
export JOBS=$(nproc)
./scripts/build.sh configs/example_config_x86_64

# Limit to specific cores
export JOBS=4
./scripts/build.sh configs/example_config_librerouter
```

#### Custom Feed Integration
```bash
# 1. Add feed to configuration
echo "src-git custom https://github.com/user/custom-feed.git" >> \
  repos/librerouteros/feeds.conf

# 2. Update feeds
cd repos/librerouteros
./scripts/feeds update custom
./scripts/feeds install -a -p custom

# 3. Build with new packages
cd ../../
./scripts/build.sh configs/example_config_x86_64
```

#### Cross-Architecture Development
```bash
# Build for different architecture
cp configs/example_config_x86_64 configs/config_mips
# Edit target architecture in config_mips
vim configs/config_mips
# Change: CONFIG_TARGET_x86=y to CONFIG_TARGET_ath79=y

./scripts/build.sh configs/config_mips
```

## Integration with Existing Scripts

This setup leverages the existing lime-app QEMU infrastructure:
- `qemu-manager.sh` - Enhanced with dual configuration support
- `qemu-image-configs.sh` - Image detection and configuration
- `qemu-network-libremesh.sh` - LibreMesh-specific network setup
- `qemu-network-librerouteros.sh` - LibreRouterOS-specific network setup
- `qemu_dev_start_librerouteros` - Custom launcher for LibreRouterOS

## Session Achievements

### Successful Problem Resolution
1. **Identified LibreRouterOS boot issue**: Kernel panic due to missing boot parameters
2. **Implemented solution**: Custom QEMU launcher with `rdinit=/sbin/init`
3. **Verified fix**: Both LibreMesh and LibreRouterOS configurations working
4. **Created comprehensive setup**: Single-script environment deployment

### Developer Experience Improvements
1. **Reduced setup time**: From manual configuration to single command
2. **Cross-platform support**: Works on multiple Linux distributions
3. **Simple workflow**: Three-command development cycle (start, deploy, stop)
4. **Comprehensive documentation**: Clear instructions and troubleshooting

### Technical Robustness
1. **Dual configuration support**: Stable and development options
2. **Automatic dependency management**: Platform-specific package installation
3. **Network isolation**: Proper bridge and TAP interface handling
4. **Error handling**: Graceful degradation and clear error messages

## Future Enhancements

### Potential Improvements
1. **Image building integration**: Automated LibreMesh/LibreRouterOS builds
2. **Multiple node support**: QEMU mesh network with multiple routers
3. **CI/CD integration**: Automated testing in QEMU environment
4. **Performance optimization**: Build caching and faster deployment

### Extension Points
1. **Additional targets**: Support for more router architectures
2. **Custom configurations**: User-defined QEMU parameters
3. **Development tools**: Integrated debugging and profiling
4. **Testing framework**: Automated lime-app testing in QEMU

## Development Tools Migration Strategy

### Current Tools in lime-app Fork

The lime-app fork contains sophisticated development tools that should be migrated to lime-dev:

#### AI Development Infrastructure
- **AI Quality Scripts** (`scripts/ai-*.sh`):
  - `ai-code-review.sh` - Automated code review with AI
  - `ai-docs-check.sh` - Documentation completeness verification
  - `ai-quality-check.sh` - Comprehensive quality analysis
  - `ai-security-scan.sh` - Security vulnerability detection
  - `ai-test-validation.sh` - Test coverage and quality validation

#### Cross-Platform Verification
- **Platform Scripts** (`scripts/verify-*.sh`):
  - `verify-setup.sh` - Complete environment verification
  - `verify-linux.sh`, `verify-macos.sh`, `verify-windows.sh` - Platform-specific checks
  - `verify-cross-platform.sh` - Multi-platform compatibility
  - `verify-ai-tools.sh` - AI toolchain verification
  - `verify-qemu.sh` - QEMU environment validation

#### Upstream Contribution Management
- **Upstream Separation System**:
  - `.upstream-exclude` - File exclusion configuration
  - `setup-upstream-aliases.sh` - Git workflow automation
  - Upstream separation documentation and strategies

#### QEMU Development Tools
- **QEMU Integration** (`scripts/qemu-*.sh`):
  - Already partially migrated but could be consolidated
  - Development workflows and automation

### Proposed Migration to lime-dev

#### 1. New Directory Structure
```bash
lime-dev/
├── tools/                      # Development tools (new)
│   ├── ai/                    # AI development scripts
│   │   ├── code-review.sh
│   │   ├── docs-check.sh
│   │   ├── quality-check.sh
│   │   ├── security-scan.sh
│   │   └── test-validation.sh
│   ├── verify/                # Verification scripts
│   │   ├── setup.sh
│   │   ├── platforms/
│   │   │   ├── linux.sh
│   │   │   ├── macos.sh
│   │   │   └── windows.sh
│   │   ├── cross-platform.sh
│   │   ├── ai-tools.sh
│   │   └── qemu.sh
│   ├── upstream/              # Upstream contribution tools
│   │   ├── setup-aliases.sh
│   │   ├── exclude-config
│   │   └── README.md
│   └── qemu/                  # Consolidated QEMU tools
│       └── (existing + new)
```

#### 2. Integration Benefits
- **Centralized Development**: All tools in one repository
- **Clean lime-app**: Upstream-ready without development infrastructure
- **Shared Tools**: Available for all managed repositories (lime-app, lime-packages, librerouteros)
- **Consistent Workflows**: Unified development experience across projects

#### 3. Repository Naming Consideration

Consider renaming to **`lime-dev`** to better reflect its purpose:
- `lime-dev` suggests only building firmware
- `lime-dev` encompasses development, testing, tooling, and building
- Better communicates the repository's role as a development environment

### Complete Migration Plan (lime-dev)

#### Phase 1: Repository Rename and Structure
```bash
# 1.1 Rename repository (GitHub/remote)
lime-dev → lime-dev

# 1.2 Create tools directory structure
mkdir -p tools/{ai,verify/platforms,upstream,qemu}
mkdir -p tools/templates/{scripts,docs}
```

#### Phase 2: AI Development Tools Migration
```bash
# 2.1 Migrate AI scripts with multi-repo support
tools/ai/
├── code-review.sh           # Adapted from lime-app
├── docs-check.sh           # Multi-repo documentation validation
├── quality-check.sh        # Cross-repository quality analysis
├── security-scan.sh        # Multi-repo security scanning
├── test-validation.sh      # Adapted for lime-app + packages testing
└── common.sh               # Shared functions and configuration
```

**Key Adaptations:**
- Support `--repo` parameter (lime-app, lime-packages, librerouteros)
- Auto-detect repository type and run appropriate checks
- Unified reporting across all managed repositories
- Common configuration in `tools/ai/common.sh`

#### Phase 3: Verification System Migration
```bash
# 3.1 Platform verification scripts
tools/verify/
├── setup.sh                # Master verification script
├── platforms/
│   ├── linux.sh           # Linux-specific checks
│   ├── macos.sh           # macOS compatibility
│   └── windows.sh         # Windows/WSL support
├── cross-platform.sh      # Multi-platform validation
├── ai-tools.sh            # AI toolchain verification
├── qemu.sh                # QEMU environment validation
└── repos.sh               # Repository integrity checks (NEW)
```

**New Features:**
- `tools/verify/repos.sh` - Validates all managed repositories
- Integrated with main CLI: `./scripts/lime verify [platform|ai|qemu|repos|all]`
- Support for CI/CD integration
- Detailed reporting with actionable suggestions

#### Phase 4: Upstream Contribution System
```bash
# 4.1 Generic upstream management
tools/upstream/
├── setup-aliases.sh        # Multi-repo git aliases
├── configs/
│   ├── lime-app.exclude    # lime-app specific exclusions
│   ├── lime-packages.exclude  # lime-packages exclusions
│   └── common.exclude      # Shared exclusions
├── generate-patch.sh       # Clean patch generation
├── validate-commit.sh      # Upstream readiness check
└── README.md              # Upstream contribution guide
```

**Enhanced Features:**
- Per-repository exclusion configurations
- Multi-repo git alias setup
- Automated patch generation for upstream PRs
- Commit validation for upstream compatibility

#### Phase 5: QEMU Tools Consolidation
```bash
# 5.1 Unified QEMU management
tools/qemu/
├── manager.sh              # Main QEMU controller (enhanced)
├── configs/
│   ├── libremesh.conf     # LibreMesh configuration
│   └── librerouteros.conf # LibreRouterOS configuration
├── network/
│   ├── setup-bridge.sh   # Network configuration
│   └── cleanup.sh        # Network cleanup
├── images/
│   ├── download.sh       # Image management
│   └── verify.sh         # Image verification
└── dev-workflow.sh       # Development workflow automation
```

**Consolidated Features:**
- Merge existing lime-app QEMU scripts
- Enhanced image management
- Automated network setup/cleanup
- Development workflow integration

#### Phase 6: Enhanced Main CLI
```bash
# 6.1 Extended lime CLI with tool integration
./scripts/lime
├── build [config]          # Existing build functionality
├── setup                   # Enhanced setup with tools
├── verify [target]         # Verification system
├── ai [command]           # AI tools interface
├── qemu [action]          # QEMU management
├── upstream [action]      # Upstream tools
└── dev [workflow]         # Development workflows
```

**New Commands:**
```bash
./scripts/lime verify all              # Complete environment check
./scripts/lime ai review --repo lime-app  # AI code review
./scripts/lime qemu dev-start          # Start development QEMU
./scripts/lime upstream prepare        # Prepare upstream PR
./scripts/lime dev setup-workspace    # Complete workspace setup
```

#### Phase 7: Documentation and Configuration
```bash
# 7.1 Updated project structure
lime-dev/
├── README.md                    # Updated for development focus
├── CLAUDE.md                    # Enhanced with tools documentation
├── docs/
│   ├── DEVELOPMENT.md          # Comprehensive development guide
│   ├── TOOLS.md               # Tools documentation
│   ├── AI_COLLABORATION.md    # AI development workflows
│   └── UPSTREAM.md            # Upstream contribution guide
├── configs/                     # Build configurations
├── tools/                      # Development tools (new)
├── scripts/                    # Core scripts
└── repos/                      # Managed repositories
```

#### Phase 8: Clean lime-app Migration
```bash
# 8.1 Remove migrated tools from lime-app
- scripts/ai-*.sh              → tools/ai/
- scripts/verify-*.sh          → tools/verify/
- scripts/setup-upstream-*.sh  → tools/upstream/
- .upstream-exclude            → tools/upstream/configs/

# 8.2 Update lime-app package.json
- Remove AI-related npm scripts
- Keep only lime-app specific scripts
- Update references to lime-dev tools

# 8.3 Clean upstream preparation
- Update .gitignore
- Remove development infrastructure
- Ensure upstream-ready state
```

#### Phase 9: Integration and Testing
```bash
# 9.1 Integration testing
./scripts/lime verify all             # Test all verification
./scripts/lime ai quality --repo all  # Test AI tools
./scripts/lime qemu dev-cycle         # Test development workflow

# 9.2 Documentation validation
./scripts/lime ai docs-check          # Validate documentation
./scripts/lime verify setup          # Test setup process

# 9.3 Cross-platform testing
./scripts/lime verify cross-platform # Multi-platform validation
```

### Implementation Timeline

**Week 1: Foundation**
- Repository rename and structure creation
- Basic CLI extension
- Documentation updates

**Week 2: Core Tools Migration**
- AI scripts migration and adaptation
- Verification system implementation
- QEMU tools consolidation

**Week 3: Integration**
- Upstream contribution system
- Enhanced CLI integration
- Cross-repo functionality

**Week 4: Validation and Cleanup**
- Comprehensive testing
- lime-app cleanup
- Documentation finalization

### Post-Migration Benefits

1. **Unified Development Environment**: Single repository for all LibreMesh development
2. **Clean Upstream Path**: lime-app ready for upstream contribution
3. **Shared Tools**: AI and verification tools available across all repositories
4. **Consistent Workflows**: Standardized development processes
5. **Better Organization**: Clear separation of concerns
6. **Enhanced Collaboration**: Centralized tools for team development

## Notes for Maintainers

### Critical Components
- `setup-lime-dev.sh` handles all initial configuration
- `dev.sh` provides the daily development interface
- `qemu-manager.sh` in lime-app manages QEMU lifecycle
- `qemu_dev_start_librerouteros` in lime-packages handles LibreRouterOS boot

### Dependencies
- Requires working lime-app qemu-manager.sh system
- Depends on lime-packages QEMU tools
- Needs system packages for QEMU virtualization
- Assumes standard LibreMesh package structure

### Maintenance
- Keep dependency lists updated for new platform versions
- Monitor LibreMesh/LibreRouterOS image format changes
- Update QEMU boot parameters as needed for new kernels
- Test on supported platforms regularly

---

This lime-dev repository represents a complete solution for LibreMesh development environment setup, built from practical problem-solving during the session and designed for ease of use by new developers.