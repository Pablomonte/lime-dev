# LibreRouterOS Build Environment

This directory contains the complete build environment for LibreRouterOS, extracted and refined from the development session. It provides a reproducible, containerized build system that solves common OpenWrt build issues.

## 🚀 Quick Start

```bash
# Clone your LibreRouterOS repository
git clone <your-librerouteros-repo> target-repo

# Build LibreRouterOS for x86_64
./build-librerouteros.sh target-repo x86_64

# Monitor the build process
./monitor-build.sh start
```

## 📁 Directory Structure

```
lime-build/
├── README.md                           # This file
├── build-librerouteros.sh             # Main build orchestrator
├── setup-environment.sh               # Environment setup script
├── Dockerfile.librerouteros-v2        # Ubuntu 18.04 build container
├── docker-build-clean.sh              # Clean Docker build script
├── docker-build-simple-manual.sh      # Manual build approach
├── build.sh                           # OpenWrt build automation
├── monitor-build.sh                   # Build progress monitoring
├── validate-config.sh                 # Configuration validation
└── docs/                              # Documentation
    ├── ARCHITECTURE.md                # Build system architecture
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    └── DEVELOPMENT.md                 # Development workflow
```

## 🛠️ Build System Features

### Docker-based Isolation
- **Ubuntu 18.04** base for GLIBC compatibility
- **Python 2.7** environment for OpenWrt requirements
- **Complete script collection** from OpenWrt upstream
- **Clean build environment** avoiding host contamination

### Automated Build Process
- **Prerequisite checking** (23 build dependencies)
- **Feed management** (packages, luci, routing, libremesh)
- **Configuration validation** (essential package selection)
- **Parallel builds** with configurable job count
- **Progress monitoring** with real-time status

### Target Support
- **LibreRouter v1** (ath79/generic) - Primary hardware
- **x86_64** - Testing and development
- **Multi-device** - Multiple ath79 devices
- **Extensible** - Easy to add new targets

## 🏗️ Build Architecture

### Phase 1: Environment Setup
1. Docker container preparation (Ubuntu 18.04)
2. OpenWrt script collection (feeds, metadata, version)
3. Build tool compilation (config, kconfig utilities)
4. Dependency resolution and validation

### Phase 2: Source Preparation
1. Feed updates (external package repositories)
2. Package installation and indexing
3. Configuration loading (target-specific configs)
4. Custom configuration application

### Phase 3: Compilation
1. Toolchain build (cross-compilation tools)
2. Host tools compilation (build utilities)
3. Kernel compilation (target-specific kernel)
4. Package building (all selected packages)
5. Firmware image generation (bootable images)

## 🔧 Configuration

### Environment Variables
```bash
export BUILD_TARGET=x86_64              # Target architecture
export BUILD_JOBS=4                     # Parallel build jobs
export BUILD_LOG_LEVEL=verbose          # Build verbosity
export DOWNLOAD_DIR=/path/to/downloads   # Package download cache
```

### Build Targets
- `librerouter` - LibreRouter v1 hardware (default)
- `x86_64` - x86_64 testing images
- `multi` - Multiple ath79 devices

## 🚨 Troubleshooting

### Common Issues
1. **GLIBC version errors** - Solved by Ubuntu 18.04 container
2. **Missing scripts** - Solved by OpenWrt script collection
3. **Python 2.x requirements** - Solved by explicit Python 2.7 setup
4. **Build failures** - Check logs with `./monitor-build.sh logs`

### Build Logs
- `docker-build-clean.log` - Docker build output
- `build.log` - OpenWrt build output (inside container)
- Monitor real-time with `./monitor-build.sh start`

## 📋 Requirements

### Host System
- Docker Engine 20.10+
- 4GB+ RAM (8GB recommended)
- 20GB+ free disk space
- Linux, macOS, or Windows with WSL2

### Network
- Internet access for package downloads
- ~2GB download for first build (cached afterward)

## 🎯 Usage Examples

### Basic Build
```bash
# Build for LibreRouter v1
./build-librerouteros.sh ../librerouteros librerouter

# Build for x86_64 testing
./build-librerouteros.sh ../librerouteros x86_64
```

### Advanced Build
```bash
# Custom job count and verbose output
BUILD_JOBS=8 BUILD_LOG_LEVEL=verbose ./build-librerouteros.sh ../librerouteros x86_64

# Build with custom download directory
DOWNLOAD_DIR=/mnt/cache/openwrt ./build-librerouteros.sh ../librerouteros x86_64
```

### Development Workflow
```bash
# Setup development environment
./setup-environment.sh

# Validate configuration
./validate-config.sh ../librerouteros

# Build and monitor
./build-librerouteros.sh ../librerouteros x86_64 &
./monitor-build.sh start
```

## 📚 Documentation

- **Architecture**: Deep dive into build system design
- **Troubleshooting**: Common issues and solutions
- **Development**: Contributing and extending the build system

## 🧪 Testing

The build environment has been tested with:
- Ubuntu 18.04 LTS (primary)
- LibreRouterOS librerouter-1.5 branch
- x86_64 and ath79 targets
- Docker Engine 20.10+

## 🤝 Contributing

This build environment was developed during a comprehensive development session that solved multiple OpenWrt build issues. Contributions are welcome to extend target support and improve automation.

## 📄 License

This build environment maintains the same license as the LibreRouterOS project it builds.

---

*Generated from development session knowledge and tested build processes.*