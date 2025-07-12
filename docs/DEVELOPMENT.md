# LibreRouterOS Development Workflow

## Quick Start
```bash
# Setup environment
./scripts/setup-lime-dev.sh

# Build LibreRouterOS firmware
./scripts/librerouteros-wrapper.sh librerouter-v1

# Or with Docker
./scripts/docker-build.sh librerouter-v1
```

## Development Cycle

1. **Environment Setup** (once)
   ```bash
   ./scripts/setup-lime-dev.sh
   ```

2. **Build Firmware**
   ```bash
   # Native build (recommended)
   ./scripts/librerouteros-wrapper.sh librerouter-v1
   
   # Docker build (when network available)
   ./scripts/docker-build.sh librerouter-v1
   ```

3. **Validation**
   ```bash
   # Check images (in librerouteros repository)
   ls -la repos/librerouteros/build/bin/targets/*/
   ```

## Supported Targets

LibreRouterOS supports these hardware targets:
- `librerouter-v1` - LibreRouter v1 hardware (default)
- `hilink_hlk-7621a-evb` - HiLink HLK-7621A evaluation board

## Build Configuration

The build system automatically uses:
- **lime-packages**: `javierbrk/lime-packages:final-release` branch
- **LibreRouterOS**: Native build system with pre-configured packages
- **OpenWrt**: Version v24.10.1 as base
