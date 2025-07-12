# Infrastructure Replication Guide

This document describes how to replicate the exact build infrastructure used for LibreMesh/LibreRouterOS development and release builds.

## Quick Start

For standard development:
```bash
git clone <lime-build-repo>
cd lime-build
./scripts/setup-lime-dev.sh
```

For release candidate testing:
```bash
git clone <lime-build-repo>
cd lime-build
LIME_RELEASE_MODE=true ./scripts/setup-lime-dev.sh
```

## Configuration System

### Central Configuration File

All repository versions, branches, and build parameters are defined in `configs/versions.conf`:

- **[repositories]** - Default repository configurations
- **[release_overrides]** - Release-specific repository overrides
- **[build_targets]** - Build target definitions
- **[firmware_versions]** - Version specifications
- **[system_requirements]** - Hardware requirements
- **[qemu_config]** - Development environment settings

### Release Mode

Set `LIME_RELEASE_MODE=true` to use release repository overrides:

```bash
# Enable release mode for current session
export LIME_RELEASE_MODE=true
./scripts/setup-lime-dev.sh

# Or for single command
LIME_RELEASE_MODE=true ./scripts/setup-lime-dev.sh
```

In release mode, the system will use:
- `javierbrk/lime-packages:final-release` instead of standard lime-packages
- `javierbrk/librerouteros:main-with-lr2-support` for LibreRouter v2 support

## Repository Management

### Git Tracking

The `repos/` directory is **never tracked** in the lime-build repository:

```gitignore
# Repository Source Code - NEVER TRACK
repos/
```

This ensures:
- Clean separation between infrastructure and source code
- No accidental commits of large repository content
- Proper version control for build infrastructure only

### Tracked Files

Lime-build tracks only infrastructure:
- `scripts/` - Build and setup automation
- `configs/` - Version and build configurations
- `docs/` - Documentation
- `Dockerfile*` - Container definitions
- `docker-compose.yml` - Container orchestration

### Repository Cloning

Repositories are cloned with proper remote tracking:

```bash
# Development repositories
lime-app: github.com/libremesh/lime-app:master
lime-packages: github.com/libremesh/lime-packages:master
librerouteros: gitlab.com/librerouter/librerouteros:librerouter-1.5
openwrt: Developer-specified: git clone -b v24.10.1 --single-branch https://git.openwrt.org/openwrt/openwrt.git

# Release repositories (when LIME_RELEASE_MODE=true)
lime-packages: github.com/javierbrk/lime-packages:final-release
librerouteros: gitlab.com/javierbrk/librerouteros:main-with-lr2-support
```

## Environment Variables

The build system exports comprehensive environment variables:

### Build Configuration
```bash
LIME_BUILD_DIR          # Root build directory
LIME_REPOS_DIR          # Repository directory
LIME_CACHE_DIR          # Build cache directory
LIME_LOGS_DIR           # Build logs directory
LIME_RELEASE_MODE       # Release mode flag (true/false)
```

### Version Information
```bash
OPENWRT_VERSION         # OpenWrt version (24.10.1)
LIBREMESH_VERSION       # LibreMesh version (23.05.5)
LIBREROUTEROS_VERSION   # LibreRouterOS version (24.10.1)
```

### Build Targets
```bash
DEFAULT_TARGET          # Default build target (librerouter-v1)
DEVELOPMENT_TARGET      # Development target (x86_64)
MULTI_TARGET           # Multi-device target (ath79-generic)
```

### Repository Paths
```bash
REPO_LIME_APP_DIR       # Path to lime-app repository
REPO_LIME_PACKAGES_DIR  # Path to lime-packages repository
REPO_LIBREROUTEROS_DIR  # Path to librerouteros repository
```

## Usage Examples

### Development Setup
```bash
# Clone and set up development environment
git clone <lime-build-repo>
cd lime-build
./scripts/setup-lime-dev.sh

# Start development
./dev.sh start
./dev.sh deploy
```

### Release Candidate Testing
```bash
# Set up for release testing
export LIME_RELEASE_MODE=true
./scripts/setup-lime-dev.sh

# Verify release repositories
./scripts/update-repos.sh status
```

### Environment Inspection
```bash
# Show current environment
./scripts/env-setup.sh show

# Check system requirements
./scripts/env-setup.sh check

# Parse configuration
./scripts/config-parser.sh repo lime_packages
./scripts/config-parser.sh get firmware_versions openwrt_version
```

## System Requirements

Defined in `configs/versions.conf`:

**Minimum:**
- 4GB RAM
- 10GB disk space
- Linux with KVM support

**Recommended:**
- 8GB RAM
- 20GB disk space
- Ubuntu/Debian with Docker

## Customization

### Adding New Repositories

Edit `configs/versions.conf`:

```ini
[repositories]
new_repo=https://github.com/user/repo.git|main|origin

[release_overrides]
new_repo_release=https://github.com/fork/repo.git|release-branch|fork
```

Update `scripts/setup-lime-dev.sh` to include the new repository in the clone loop.

### Changing Default Versions

Update version specifications in `configs/versions.conf`:

```ini
[firmware_versions]
openwrt_version=24.10.2
libremesh_version=23.05.6
```

### Build Target Modifications

Modify build targets in `configs/versions.conf`:

```ini
[build_targets]
default_target=librerouter-v2
development_target=x86_64
```

## Troubleshooting

### Repository Tracking Issues

If repositories appear as modified in git status:

```bash
# Check if repos/ is properly ignored
git check-ignore repos/
# Should output: repos/

# If not ignored, add to .gitignore
echo "repos/" >> .gitignore
```

### Environment Setup Issues

```bash
# Verify configuration parsing
./scripts/config-parser.sh help

# Check environment setup
./scripts/env-setup.sh check

# Reset and retry
rm -rf repos/
./scripts/setup-lime-dev.sh
```

### Release Mode Issues

```bash
# Verify release mode is active
./scripts/config-parser.sh release

# Check repository configurations
./scripts/config-parser.sh repo lime_packages_release
```

## Best Practices

1. **Never modify repos/ tracking**
   - Always keep `repos/` in .gitignore
   - Never commit repository content

2. **Use centralized configuration**
   - Update `configs/versions.conf` for version changes
   - Don't hardcode URLs or versions in scripts

3. **Test both modes**
   - Verify development setup works
   - Test release mode for pre-release candidates

4. **Environment isolation**
   - Use the provided environment setup scripts
   - Export necessary variables consistently

5. **Documentation updates**
   - Update this guide when adding new features
   - Document any configuration changes