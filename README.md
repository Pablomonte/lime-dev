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

# Set up environment (safe, interactive)
./scripts/lime setup install

# Build firmware (native method, fastest)
./scripts/lime build

# Or build with Docker (containerized, requires network)
./scripts/lime build docker
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

### Build Commands

```bash
# Main interface (recommended)
./scripts/lime build                     # Native build (fastest)
./scripts/lime build docker              # Docker build (isolated)
./scripts/lime build --clean             # Clean environment

# Specific targets
./scripts/lime build native librerouter-v1        # LibreRouter v1
./scripts/lime build native hilink_hlk-7621a-evb  # HiLink board

# Development options
./scripts/lime build native --download-only       # Dependencies only
./scripts/lime build docker --shell               # Interactive shell
```

### Setup Commands

```bash
# Environment management
./scripts/lime setup check              # Check current status
./scripts/lime setup install            # Safe interactive setup
./scripts/lime setup install --release  # Release testing setup
./scripts/lime update                   # Update repositories
```


## Build System

LibreRouterOS uses its native build system with two methods:

- **Native Build**: Direct execution with environment setup
- **Docker Build**: Containerized build using original LibreRouterOS Dockerfile

Both methods use the same underlying `librerouteros_build.sh` script with 
the `final-release` lime-packages configuration.

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