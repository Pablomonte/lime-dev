# LibreRouterOS Build Architecture

## Overview
The LibreRouterOS build system is based on a containerized OpenWrt build environment that solves common compatibility issues.

## Components

### Docker Container (Ubuntu 18.04)
- Solves GLIBC version compatibility issues
- Provides Python 2.7 environment required by OpenWrt
- Isolates build environment from host system

### Build Scripts
- `build-librerouteros.sh` - Main orchestrator
- `docker-build-clean.sh` - Docker-based build
- `build.sh` - OpenWrt build automation
- `monitor-build.sh` - Progress monitoring

### Script Collection
- Complete OpenWrt scripts from upstream
- Feed management and package metadata
- Configuration and validation tools

## Build Process

1. **Environment Setup**
   - Docker container preparation
   - Script collection validation
   - Dependency checking

2. **Source Preparation**
   - Feed updates and installation
   - Configuration loading
   - Package dependency resolution

3. **Compilation**
   - Toolchain build
   - Package compilation
   - Firmware image generation

## Target Support
- LibreRouter v1 (ath79/generic)
- x86_64 (testing)
- Multi-device (multiple ath79)
