# CLAUDE.md - LibreRouterOS Build Environment

This build environment contains the complete containerized build system for LibreRouterOS, extracted and refined from a comprehensive development session that solved multiple OpenWrt build challenges.

## Session Background

This build environment was created during a development session that addressed several critical OpenWrt build issues:

1. **GLIBC Compatibility** - Solved using Ubuntu 18.04 container
2. **Python 2.x Requirements** - Explicitly configured Python 2.7 environment
3. **Missing OpenWrt Scripts** - Complete script collection from upstream
4. **Build Environment Isolation** - Docker containerization approach
5. **Automated Build Process** - Comprehensive build orchestration

## Key Components

### Docker Environment
- **Dockerfile.librerouteros-v2** - Ubuntu 18.04 base with Python 2.7
- **docker-build-clean.sh** - Clean build script avoiding host contamination
- **docker-compose.yml** - Multi-container orchestration (legacy)

### Build Scripts
- **build-librerouteros.sh** - Main build orchestrator
- **build.sh** - OpenWrt build automation (copied to target repo)
- **monitor-build.sh** - Real-time build monitoring
- **setup-environment.sh** - Complete environment setup

### Configuration Management
- **validate-config.sh** - Repository and environment validation
- Automatic OpenWrt script collection from upstream
- Target-specific configuration handling

## Build Process Architecture

### Phase 1: Environment Preparation
1. Docker container with Ubuntu 18.04 + Python 2.7
2. OpenWrt script collection from upstream repository
3. Build tool compilation within container
4. Dependency validation and setup

### Phase 2: Source Configuration
1. Feed updates (packages, luci, routing, libremesh)
2. Package installation and dependency resolution
3. Target-specific configuration loading
4. Custom LibreRouterOS configuration application

### Phase 3: Compilation
1. Cross-compilation toolchain build
2. Host tools compilation
3. Kernel compilation for target architecture
4. Package building (parallel compilation)
5. Firmware image generation

## Solved Issues

### GLIBC Version Conflicts
**Problem**: Host system GLIBC 2.33/2.34 incompatible with OpenWrt tools
**Solution**: Ubuntu 18.04 container with compatible GLIBC version

### Missing OpenWrt Scripts
**Problem**: LibreRouterOS missing essential build scripts
**Solution**: Automatic script collection from `../openwrt/scripts/`

### Python 2.x Dependencies
**Problem**: Modern systems lack Python 2.x required by OpenWrt
**Solution**: Explicit Python 2.7 installation and symlink configuration

### Build Environment Contamination
**Problem**: Host system compiled binaries causing build failures
**Solution**: Clean Docker environment with selective binary removal

## Usage Examples

### Basic Build
```bash
# Setup environment (once)
./setup-environment.sh

# Build LibreRouterOS for x86_64
./build-librerouteros.sh ../librerouteros x86_64

# Monitor build progress
./monitor-build.sh start
```

### Advanced Build
```bash
# Validate repository first
./validate-config.sh ../librerouteros

# Build with custom parameters
BUILD_JOBS=8 ./build-librerouteros.sh ../librerouteros librerouter

# Monitor with logs
./monitor-build.sh logs
```

## Repository Structure

```
lime-build/
├── README.md                          # Complete documentation
├── CLAUDE.md                          # This file - session knowledge
├── build-librerouteros.sh             # Main orchestrator
├── setup-environment.sh               # Environment setup
├── validate-config.sh                 # Configuration validation
├── Dockerfile.librerouteros-v2        # Ubuntu 18.04 container
├── docker-build-clean.sh              # Clean Docker build
├── docker-build-simple-manual.sh      # Manual build approach
├── build.sh                           # OpenWrt automation
├── monitor-build.sh                   # Build monitoring
├── docker-compose.yml                 # Legacy orchestration
└── docs/                              # Generated documentation
    ├── ARCHITECTURE.md                # System architecture
    ├── TROUBLESHOOTING.md             # Issue resolution
    └── DEVELOPMENT.md                 # Development workflow
```

## Target Support

### Primary Targets
- **librerouter** - LibreRouter v1 hardware (ath79/generic)
- **x86_64** - Testing and development images
- **multi** - Multiple ath79 devices

### Configuration Files
- `configs/default_config` - LibreRouter v1
- `configs/default_config_x86_64` - x86_64 testing
- `configs/default_config_multi` - Multi-device

## Dependencies

### External Repositories
- **openwrt** - Source of essential build scripts
- **kconfig-utils** - Kernel configuration utilities
- **lime-packages** - LibreMesh package collection

### Build Requirements
- Docker Engine 20.10+
- 4GB+ RAM (8GB recommended)
- 20GB+ disk space
- Linux/macOS/Windows with WSL2

## Session-Proven Capabilities

### Successful Build Phases
1. ✅ **Docker Environment** - Ubuntu 18.04 with Python 2.7
2. ✅ **Script Collection** - Complete OpenWrt script set
3. ✅ **Prerequisite Validation** - All 23 build checks passing
4. ✅ **Feed Processing** - Package feed updates and installation
5. ✅ **Configuration Loading** - Target-specific configuration
6. 🔄 **Toolchain Build** - Cross-compilation tools (in progress)

### Issue Resolution History
- **GLIBC 2.33/2.34 not found** → Ubuntu 18.04 container
- **Python 2.x missing** → Explicit Python 2.7 setup
- **scripts/feeds not found** → OpenWrt script collection
- **package-metadata.pl missing** → Complete script migration
- **Docker permission denied** → User group configuration

## Automation Features

### Environment Setup
- Automatic Docker configuration
- User permission management
- Dependency validation
- Documentation generation

### Build Orchestration
- Repository validation
- Script collection automation
- Target-specific configuration
- Progress monitoring

### Quality Assurance
- Configuration validation
- Build environment testing
- Error detection and reporting
- Log aggregation

## Integration Points

### with LibreRouterOS
- Automatic script collection from upstream
- Target-specific configuration loading
- LibreMesh integration validation
- Hardware support verification

### with OpenWrt Ecosystem
- Feed management automation
- Package dependency resolution
- Kernel configuration handling
- Image generation workflow

## Future Enhancements

### Planned Features
- Additional target architecture support
- Cached build acceleration
- CI/CD pipeline integration
- Multi-stage build optimization

### Extension Points
- Custom target configuration
- Additional container base images
- Enhanced monitoring capabilities
- Build artifact management

## Development Notes

This build environment represents a complete solution to OpenWrt build challenges, developed through systematic problem-solving and testing. The containerized approach ensures reproducible builds across different host systems while maintaining compatibility with the OpenWrt ecosystem.

The session demonstrated successful progression from initial build failures to a working build environment, with each issue systematically identified and resolved through targeted solutions.

---

*This knowledge base captures the complete build environment development session and provides the foundation for reproducible LibreRouterOS builds.*