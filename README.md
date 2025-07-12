# Lime-Build

A comprehensive build environment and development toolkit for LibreMesh, LibreRouterOS, and related projects.

## Overview

Lime-Build provides a unified environment for:
- Building LibreRouterOS firmware with Docker
- Developing and testing lime-app with QEMU
- Managing LibreMesh packages
- Cross-platform build automation

## Project Structure

```
lime-build/
├── repos/                 # Source repositories
│   ├── librerouteros/     # LibreRouterOS firmware (OpenWrt-based)
│   ├── lime-app/          # LibreMesh web interface
│   ├── lime-packages/     # LibreMesh package collection
│   └── kconfig-utils/     # Kernel configuration utilities
├── scripts/               # Build and automation scripts
│   ├── docker-build.sh    # Main Docker build script
│   ├── build.sh           # Direct build with options
│   ├── setup-lime-dev.sh  # Development environment setup
│   └── ...                # Additional utility scripts
├── configs/               # Build configurations
├── docs/                  # Documentation
├── Dockerfiles/           # Docker build environments
├── cache/                 # Build cache (git-ignored)
└── logs/                  # Build logs (git-ignored)
```

## Quick Start

### For LibreRouterOS Firmware Building

```bash
# Clone this repository
git clone <your-lime-build-repo>
cd lime-build

# Build using Docker (recommended)
./scripts/docker-build.sh

# Or build directly
./scripts/build.sh
```

### For lime-app Development

```bash
# Set up complete development environment
./scripts/setup-lime-dev.sh

# Start QEMU mesh simulation
./scripts/dev.sh start

# Deploy changes to QEMU
./scripts/dev.sh deploy

# Access lime-app
firefox http://10.13.0.1/app/
```

## Build Options

### Docker Build (Recommended)

```bash
# Standard build
./scripts/docker-build.sh

# Clean build (removes previous artifacts)
./scripts/docker-build-clean.sh

# Simple manual build
./scripts/docker-build-simple-manual.sh
```

### Direct Build

```bash
# Build for LibreRouter v1 (default)
./scripts/build.sh

# Build for specific target
./scripts/build.sh -t x86_64
./scripts/build.sh -t multi     # Multiple ath79 devices

# Individual build steps
./scripts/build.sh prereq       # Check prerequisites
./scripts/build.sh feeds        # Update feeds
./scripts/build.sh config       # Configure target
./scripts/build.sh menuconfig   # Interactive config
./scripts/build.sh build        # Build firmware

# Cleaning
./scripts/build.sh clean        # Clean build
./scripts/build.sh dirclean     # Deep clean
./scripts/build.sh distclean    # Full reset
```

## Docker Environments

- `Dockerfile.librerouteros` - Main build environment
- `Dockerfile.librerouteros-v2` - Alternative configuration
- `Dockerfile.build-py2` - Python 2 compatibility support

Using Docker Compose:
```bash
docker-compose up build-env
```

## Development Features

### QEMU Mesh Network Simulation
- Automatic network bridge configuration
- TAP interface management
- Support for multiple firmware versions
- Console access via screen

### Repository Management
- Centralized repository structure
- Git submodule alternative
- Coordinated versioning

### Build Automation
- Multi-platform support (Ubuntu, Debian, RHEL, Arch)
- Dependency management
- Build artifact caching
- Real-time monitoring

## Requirements

### System Requirements
- Linux OS (Ubuntu/Debian recommended)
- 8GB+ RAM (4GB minimum)
- 20GB+ free disk space
- Docker and Docker Compose
- Git

### For QEMU Development
- KVM support (recommended)
- Network administration privileges
- Node.js 18+ (auto-installed)

## Supported Platforms

### Build Targets
- LibreRouter v1 (ath79/QCA9558)
- LibreRouter v2 (in development)
- x86_64 (testing)
- TP-Link devices (various models)

### Firmware Versions
- LibreMesh 23.05.5 (stable)
- LibreRouterOS 24.10.1 (development)
- OpenWrt 24.10.1 base

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

## Troubleshooting

### Build Issues
- Check Docker daemon is running
- Verify sufficient disk space
- Review logs in `logs/` directory

### QEMU Issues
- Ensure KVM modules loaded: `lsmod | grep kvm`
- Check network bridges: `ip addr show lime_br0`
- Console access: `sudo screen -r libremesh`

### Common Solutions
```bash
# Reset QEMU environment
./scripts/dev.sh stop && ./scripts/dev.sh start

# Clean Docker build
./scripts/docker-build-clean.sh

# Check build dependencies
./scripts/build.sh prereq
```

## License

This build environment is licensed under GPL-3.0. Individual repositories maintain their own licenses:
- LibreRouterOS: GPL-2.0
- lime-app: AGPL-3.0
- lime-packages: AGPL-3.0

## Links

- [LibreMesh Project](https://libremesh.org)
- [LibreRouter Hardware](https://librerouter.org)
- [OpenWrt Project](https://openwrt.org)

---

**Note**: This is an active development environment. For production firmware, use official releases from the LibreMesh project.