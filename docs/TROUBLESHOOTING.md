# LibreMesh Development Environment Troubleshooting

## Common Build Issues

### Docker Permission Errors
```
permission denied while trying to connect to the Docker daemon socket
```
**Solution**: Add user to docker group
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### GLIBC Version Errors
```
version `GLIBC_2.33' not found
```
**Solution**: Use Ubuntu 18.04 container (automatically handled)

### Missing Scripts
```
./scripts/feeds: not found
```
**Solution**: Ensure OpenWrt repository is available for script copying

### Build Failures
- Check logs with `./lime build --clean`
- Verify target repository is valid OpenWrt
- Ensure sufficient disk space (20GB+)
- Check memory availability (4GB+)

## LibreRouter v1 Upgrade Utility

### LibreRouter v1 Issues

**Problem**: LibreRouter v1 (pre-1.5 firmware) cannot upgrade firmware normally.

**Solution**: Update safe-upgrade script first:
```bash
./lime upgrade
```

**Common Issues:**

*SSH Connection Rejected*
```
Unable to negotiate with router: no matching host key type found
```
Fix: `ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info`

*SCP/SFTP Not Working*
```
ash: /usr/libexec/sftp-server: not found
```
Fix: Expected on legacy routers - script uses hex transfer instead.

*Router Not Found*
- Try: `thisnode.info`, `10.13.0.1`, `192.168.1.1`
- Default password: `toorlibre1`
- Connect to router's WiFi first

## QEMU Development Issues

### QEMU Not Starting
- Check KVM is available: `kvm-ok`
- Verify user in kvm group: `groups | grep kvm`
- Ensure bridge interfaces exist
- Check image files are present in `repos/lime-packages/build/`

### Network Issues in QEMU
- Verify bridge interface: `ip addr show lime_br0`
- Check TAP interfaces: `ip addr show | grep lime_tap`
- Reset network: `sudo ip link delete lime_br0 2>/dev/null || true`

### LibreRouterOS Kernel Boot Issues
- Uses kernel 6.6.86 which requires specific boot parameters
- Handled automatically by `qemu_dev_start_librerouteros`
- If issues persist, try LibreMesh image instead

## Build System Issues

### Cross-Platform Compatibility
- **Ubuntu/Debian**: Full support
- **RHEL/CentOS/Fedora**: Supported via yum/dnf
- **Arch Linux**: Supported via pacman
- **macOS**: Limited QEMU performance

### Dependency Installation
```bash
# Check setup status
./lime verify all

# Install missing dependencies
./lime setup install
```

### Cache and Storage
- Build cache: `cache/` directory (can be large)
- Logs: `logs/` directory
- Clean cache: `./lime clean`
- Check disk space: `df -h`

## Getting Help

### Environment Verification
```bash
# Check complete environment
./lime verify all

# Check specific components
./lime verify platform    # Platform-specific checks
./lime verify qemu        # QEMU environment
./lime verify repos       # Repository integrity
```

### Reset Environment
```bash
# Clean build artifacts
./lime clean

# Reset repositories
./lime update

# Complete setup verification
./lime setup check
```

### Advanced Debugging
```bash
# Verbose build output
export V=s
./lime build configs/example_config_x86_64

# Check specific package build
cd repos/librerouteros
make package/lime-system/compile V=s
```

## Performance Optimization

### Build Performance
- Use all CPU cores: `export JOBS=$(nproc)`
- Limit cores: `export JOBS=4`
- Use cache directory: `export DOWNLOAD_DIR=/cache`

### Memory Requirements
- Minimum: 4GB RAM
- Recommended: 8GB+ RAM
- Disk space: 20GB+ free space

### Network Performance
- QEMU uses bridge interfaces for networking
- Performance may vary based on host network configuration
- Use wired connection for best QEMU performance

## System Requirements

### Host System
- Linux preferred (Ubuntu 20.04+ recommended)
- macOS supported (limited performance)
- Windows via WSL2 (experimental)

### Required Tools
- Git
- Docker (optional but recommended)
- SSH client
- sshpass (for legacy router updates)
- QEMU (for development)
- Standard build tools (gcc, make, etc.)

### Network Access
- Internet connection for downloading packages
- Access to GitHub for repository cloning
- SSH access to target routers (for legacy updates)
