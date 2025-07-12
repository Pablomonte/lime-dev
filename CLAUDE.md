# CLAUDE.md - lime-build Development Environment

## Repository Purpose

This repository provides a single-script setup for LibreMesh lime-app development with QEMU mesh network simulation. It consolidates the development environment setup that was created during the session for debugging LibreRouterOS kernel boot issues and establishing dual-configuration QEMU support.

## Session Background

This development environment was created to solve the challenge of providing new lime-app developers with a complete, working development setup. The session addressed:

1. **LibreRouterOS Boot Issues** - Solved kernel 6.6.86 boot parameter problems
2. **Dual Configuration Support** - LibreMesh 23.05.5 stable + LibreRouterOS 24.10.1 development
3. **QEMU Network Setup** - Bridge interfaces, TAP devices, KVM acceleration
4. **Developer Onboarding** - Single-script setup from zero to productive development

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
git clone <lime-build-repo>
cd lime-build
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

```
lime-build/
├── setup-lime-dev.sh    # Main setup script
├── dev.sh               # Development helper
├── README.md             # User documentation
├── CLAUDE.md             # This file - session knowledge
├── lime-app/            # LibreMesh web interface (cloned)
├── lime-packages/       # LibreMesh packages + QEMU tools (cloned)
└── openwrt/             # OpenWrt source (cloned)
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

This lime-build repository represents a complete solution for LibreMesh development environment setup, built from practical problem-solving during the session and designed for ease of use by new developers.