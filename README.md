# Lime-Dev

A development environment and build system for LibreMesh, LibreRouterOS, and related projects. Provides code analysis tools, environment verification, upstream contribution workflows, and build automation.

## Overview

Lime-Dev includes:
- LibreRouterOS firmware build system (native and Docker)
- QEMU-based lime-app development environment
- LibreMesh package management
- Code analysis and quality checking tools
- Environment verification scripts
- Git workflow automation for upstream contributions
- Cross-platform setup scripts

## Project Structure

```
lime-dev/
├── repos/                 # Managed source repositories
│   ├── librerouteros/     # LibreRouterOS firmware (OpenWrt-based)
│   ├── lime-app/          # LibreMesh web interface
│   ├── lime-packages/     # LibreMesh package collection
│   └── kconfig-utils/     # Kernel configuration utilities
├── scripts/               # Core build and automation scripts
│   ├── lime               # Main CLI interface
│   ├── build.sh           # Build management
│   ├── setup.sh           # Environment setup
│   └── core/              # Core functionality scripts
├── tools/                 # Development tools
│   ├── ai/                # AI-powered analysis tools
│   ├── verify/            # Environment verification
│   ├── upstream/          # Upstream contribution tools
│   └── qemu/              # QEMU management tools
├── configs/               # Build configurations
├── docs/                  # Documentation
├── cache/                 # Build cache (git-ignored)
└── logs/                  # Build logs (git-ignored)
```

## Quick Start

### Complete Setup

```bash
# Clone this repository
git clone <your-lime-dev-repo>
cd lime-dev

# Set up complete development environment
./scripts/lime setup install

# Verify environment
./scripts/lime verify all

# Build firmware
./scripts/lime build
```

### Code Analysis

```bash
# Code review for all repositories
./scripts/lime ai review --repo all

# Security scan
./scripts/lime ai security --repo all

# Documentation validation
./scripts/lime ai docs --repo lime-app

# Quality assessment
./scripts/lime ai quality --repo lime-packages --verbose
```

### QEMU Development

```bash
# Start QEMU mesh simulation
./scripts/lime qemu start

# Access lime-app at http://10.13.0.1/app/
# Make changes, then:

# Stop QEMU environment
./scripts/lime qemu stop
```

### Upstream Contribution

```bash
# Configure upstream remotes and git aliases
./scripts/lime upstream setup all

# Show available git aliases
./scripts/lime upstream aliases lime-app
```

## Main CLI Interface

The `lime` command provides unified access to all functionality:

### Build Commands
```bash
./scripts/lime build                     # Native build (fastest)
./scripts/lime build docker              # Docker build (isolated)
./scripts/lime build --clean             # Clean environment
```

### Verification Commands
```bash
./scripts/lime verify all                # Complete environment verification
./scripts/lime verify platform           # Platform-specific checks
./scripts/lime verify setup --quick      # Quick setup verification
```

### Code Analysis Tools
```bash
./scripts/lime ai review --repo lime-app      # Code review
./scripts/lime ai security --repo all         # Security scan
./scripts/lime ai quality --repo all          # Quality assessment
./scripts/lime ai docs --repo lime-packages   # Documentation check
./scripts/lime ai test --repo lime-app        # Test validation
```

### Environment Management
```bash
./scripts/lime setup install             # Complete setup
./scripts/lime setup check               # Check status
./scripts/lime update                    # Update repositories
./scripts/lime clean                     # Clean artifacts
```

## Code Analysis Features

### Analysis Tools
- **Code Review**: Code quality analysis with repository-specific checks
- **Security Scanning**: Detection of hardcoded secrets and dangerous function usage
- **Quality Assessment**: Code metrics, complexity analysis, maintainability scoring
- **Documentation Validation**: README completeness and inline documentation coverage
- **Test Coverage**: Test structure analysis and coverage estimation

### Multi-Repository Support
- Consistent analysis across lime-app, lime-packages, and librerouteros
- Repository-type detection (Node.js, OpenWrt, Makefile projects)
- Standardized reporting and output formatting
- Batch operations across managed repositories

## Platform Verification

### Cross-Platform Support
- **Linux**: Full verification with distribution-specific package management
- **macOS**: Homebrew integration and Xcode tools validation
- **Windows/WSL**: WSL2 support with performance optimization recommendations

### Environment Validation
- System requirements verification
- Development tool availability
- QEMU and virtualization support
- Network configuration validation
- Build tool compatibility

## Upstream Contribution Management

### Git Workflow Integration
- Automatic upstream remote configuration
- Pre-configured git aliases for contribution workflows
- Branch management and synchronization helpers
- Clean contribution preparation

### Repository-Specific Configuration
- Exclusion patterns for development-only files
- Upstream readiness validation
- Automated patch generation
- Pre-commit hooks for contribution quality

## Build System

### Build Methods
- **Native Build**: Direct execution with environment setup (fastest)
- **Docker Build**: Containerized build using LibreRouterOS Dockerfile (isolated)

### Supported Targets
- LibreRouter v1 (ath79/QCA9558)
- x86_64 (testing and virtualization)
- TP-Link devices (various models)
- Custom OpenWrt targets

### Firmware Versions
- LibreMesh 23.05.5 (stable)
- LibreRouterOS 24.10.1 (development)
- OpenWrt 24.10.1 base

## QEMU Development Environment

### Features
- Automatic network bridge configuration
- TAP interface management
- Support for multiple firmware versions
- Console access via screen
- Live development workflow

### Network Configuration
- Bridge interface: lime_br0 (10.13.0.2/16)
- QEMU guest IP: 10.13.0.1
- TAP interfaces: lime_tap00_0, lime_tap00_1, lime_tap00_2

## Requirements

### System Requirements
- Linux OS (Ubuntu/Debian recommended)
- 8GB+ RAM (4GB minimum)
- 20GB+ free disk space
- Internet connection for setup

### Optional Requirements
- Docker for containerized builds
- KVM support for QEMU acceleration
- Node.js 18+ (auto-installed for lime-app development)

### AI Tools Dependencies
- ripgrep (rg) for fast text searching
- jq for JSON processing
- Python 3 for advanced analysis

## Development Workflows

### Feature Development
```bash
# 1. Verify environment
./scripts/lime verify all

# 2. Create feature branch
cd repos/lime-app
git feature-start my-new-feature

# 3. Develop with AI assistance
./scripts/lime ai review --repo lime-app
./scripts/lime ai test --repo lime-app

# 4. Test in QEMU
./scripts/lime qemu start

# 5. Contribute upstream
./scripts/lime upstream setup lime-app
git create-patch
```

### Quality Assurance
```bash
# Complete quality check
./scripts/lime ai quality --repo all --format json --output qa-report.json

# Security audit
./scripts/lime ai security --repo all

# Documentation review
./scripts/lime ai docs --repo all
```

### Multi-Repository Development
```bash
# Setup all repositories for upstream
./scripts/lime upstream setup all

# Sync with upstream changes
cd repos/lime-app && git upstream-sync
cd ../lime-packages && git upstream-sync
cd ../librerouteros && git upstream-sync
```

## Contributing

Contributions welcome! The development workflow:

1. **Setup**: `./scripts/lime setup install`
2. **Verify**: `./scripts/lime verify all`
3. **Develop**: Use AI tools for quality assurance
4. **Test**: QEMU environment for integration testing
5. **Contribute**: Upstream contribution tools

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.

## Troubleshooting

### Environment Issues
```bash
# Complete verification
./scripts/lime verify all

# Platform-specific checks
./scripts/lime verify platform --verbose

# Check specific components
./scripts/lime verify qemu
```

### Build Issues
```bash
# Clean and rebuild
./scripts/lime clean
./scripts/lime build

# Docker build issues
./scripts/lime build docker --shell
```

### QEMU Issues
```bash
# Check status
./scripts/lime qemu status

# Reset environment
./scripts/lime qemu stop
./scripts/lime qemu start
```

### AI Tools Issues
```bash
# Verify AI dependencies
./scripts/lime verify all

# Test individual tools
./scripts/lime ai review --repo lime-app --verbose
```

## Advanced Usage

### Custom Build Configurations
```bash
# Use specific configuration
./scripts/lime build configs/my_custom_config
```

### AI Tool Customization
```bash
# Custom output formatting
./scripts/lime ai quality --repo all --format markdown --output report.md

# Batch analysis
for repo in lime-app lime-packages librerouteros; do
    ./scripts/lime ai security --repo $repo --output security-$repo.json
done
```

### Upstream Workflow
```bash
# Show available aliases
./scripts/lime upstream aliases lime-app

# Example workflow
cd repos/lime-app
git feature-start new-feature
# ... make changes ...
git feature-sync
git create-patch
git upstream-sync
```

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Development Guide](docs/DEVELOPMENT.md) 
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Script Consolidation](docs/SCRIPT_CONSOLIDATION.md)
- [Contributing Guidelines](docs/CONTRIBUTING.md)

## License

This development environment is licensed under GPL-3.0. Individual repositories maintain their own licenses:
- LibreRouterOS: GPL-2.0
- lime-app: AGPL-3.0
- lime-packages: AGPL-3.0

## Links

- [LibreMesh Project](https://libremesh.org)
- [LibreRouter Hardware](https://librerouter.org)
- [OpenWrt Project](https://openwrt.org)

---

**Note**: This development environment consolidates tools and workflows for LibreMesh ecosystem development. For production firmware builds, refer to official LibreMesh project releases.