# LibreRouterOS Development Workflow

## Quick Start
```bash
# Setup environment
./setup-environment.sh

# Build for testing
./build-librerouteros.sh ../librerouteros x86_64

# Monitor build
./monitor-build.sh start
```

## Development Cycle

1. **Environment Setup** (once)
   ```bash
   ./setup-environment.sh
   ```

2. **Repository Preparation**
   ```bash
   git clone <repo> target-repo
   cd target-repo
   # Make changes
   ```

3. **Build and Test**
   ```bash
   ../lime-build/build-librerouteros.sh . x86_64
   ```

4. **Validation**
   ```bash
   # Check images
   ls -la bin/targets/*/
   
   # Test in QEMU
   qemu-system-x86_64 -m 512 -nographic -kernel bin/targets/x86/64/openwrt-*-kernel.bin
   ```

## Adding New Targets
1. Create configuration file in `configs/`
2. Add target to `build.sh` switch statement
3. Update `build-librerouteros.sh` validation
4. Test build process

## Extending Build System
- Add new Docker base images in `Dockerfile.*`
- Extend monitoring in `monitor-build.sh`
- Add validation in `validate-config.sh`
