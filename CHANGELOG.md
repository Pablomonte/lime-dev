# Changelog

All notable changes to the LibreRouterOS Build Environment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-07-12

### Added
- **Unified Command Interface**: Single `lime` command for all operations
- **Script Organization**: Hierarchical structure with `core/`, `utils/`, `legacy/` directories
- **Centralized Configuration**: `configs/versions.conf` for repository and build settings
- **Release Mode Support**: `--release` flag for javierbrk repository overrides
- **Infrastructure Replication**: Complete documentation and automation for environment setup
- **Safe Setup System**: User confirmation for potentially disruptive operations
- **Environment Status Checking**: Comprehensive system requirement validation
- **Smart Path Resolution**: Scripts work from any directory location
- **Git Change Detection**: Automatic stashing of uncommitted changes during updates

### Changed
- **BREAKING**: Main interface now `./scripts/lime [command]` instead of individual scripts
- **Docker System**: Integrated with native LibreRouterOS Docker instead of wrapper system
- **Build Commands**: Simplified to `lime build` (native) and `lime build docker`
- **Setup Process**: Default to safe interactive setup with `lime setup install`
- **Repository Management**: Smart branch tracking with upstream remote detection
- **Documentation**: Updated all examples to use new command interface

### Removed
- **Docker Wrapper System**: Eliminated redundant Docker configurations
- **Legacy Build Scripts**: Moved to `legacy/` directory (archived, not deleted)
- **Duplicate Setup Scripts**: Consolidated multiple setup approaches
- **Build Method Confusion**: Removed competing/conflicting build systems

### Fixed
- **Git Tracking Issues**: `repos/` directory properly ignored
- **Docker Integration**: Uses original LibreRouterOS Docker system correctly
- **Environment Mapping**: Native builds work with lime-build repository structure
- **OpenWrt Source**: Uses developer-specified exact clone command
- **Path Dependencies**: All scripts work regardless of current working directory

### Security
- **Non-disruptive Defaults**: Safe setup as default path with user confirmation
- **Change Preservation**: Git stashing prevents loss of local modifications
- **Environment Isolation**: Proper separation between infrastructure and source repositories

## [1.0.0] - 2025-07-10

### Added
- Complete containerized build environment for LibreRouterOS
- Docker setup with Ubuntu 18.04 and Python 2.7 for OpenWrt compatibility
- Build orchestration script (`build-librerouteros.sh`)
- Environment setup automation (`setup-environment.sh`)
- Configuration validation tools (`validate-config.sh`)
- Real-time build monitoring (`monitor-build.sh`)
- OpenWrt build automation (`build.sh`)
- Comprehensive documentation (README.md, CLAUDE.md, docs/)
- Example configurations for LibreRouter v1 and x86_64 targets
- Git repository with proper .gitignore for build artifacts

### Fixed
- GLIBC version compatibility issues using Ubuntu 18.04 container
- Python 2.x requirements through explicit Python 2.7 setup
- Missing OpenWrt scripts via automatic upstream collection
- Build environment contamination through Docker isolation
- Docker permission issues with automatic user group management

### Features
- **Target Support**: LibreRouter v1 (ath79), x86_64, multi-device
- **Automation**: One-command builds with progress monitoring
- **Validation**: Repository and environment validation
- **Documentation**: Complete usage guides and troubleshooting
- **Integration**: Seamless OpenWrt and LibreMesh ecosystem compatibility

### Technical Details
- **Container**: Ubuntu 18.04 with Python 2.7 and OpenWrt dependencies
- **Scripts**: Complete OpenWrt script collection from upstream
- **Build Process**: Automated feed management, configuration, and compilation
- **Monitoring**: Real-time progress tracking and log aggregation
- **Quality**: Configuration validation and error detection

### Development Session
This release captures the complete build environment developed during a comprehensive 
development session that systematically solved multiple OpenWrt build challenges:

1. Initial commit analysis and branch understanding
2. Build process formalization and automation
3. Docker environment configuration and testing
4. GLIBC compatibility resolution
5. Script collection and integration
6. Complete build environment packaging

The session demonstrated successful progression from build failures to a working 
environment capable of building LibreRouterOS firmware images.

---

*This changelog documents the creation of a production-ready LibreRouterOS build environment.*