# LibreRouterOS Build Troubleshooting

## Common Issues

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
- Check logs with `./monitor-build.sh logs`
- Verify target repository is valid OpenWrt
- Ensure sufficient disk space (20GB+)
- Check memory availability (4GB+)

## Build Monitoring
- Real-time: `./monitor-build.sh start`
- Logs: `./monitor-build.sh logs`
- Status: `./monitor-build.sh status`

## Performance Tuning
- Adjust job count: `BUILD_JOBS=8 ./build-librerouteros.sh ...`
- Use cache directory: `DOWNLOAD_DIR=/cache ./build-librerouteros.sh ...`



## LibreRouter v1 Legacy Firmware Upgrade

### Problem: Outdated LibreRouter v1 (pre-1.5 firmware)

LibreRouter v1 devices with firmware older than version 1.5 have several limitations:
- Require legacy SSH key algorithms: `-oHostKeyAlgorithms=+ssh-rsa`
- No sftp-server support (only scp works)
- Limited resources for direct firmware downloads
- Outdated safe-upgrade script

### Automated Solution

Use the automated upgrade script for complete firmware update:

```bash
# Full automated upgrade (recommended)
./scripts/upgrade-legacy-router.sh thisnode.info

# Or with specific IP
./scripts/upgrade-legacy-router.sh 192.168.1.1
```

**What the script does:**
1. Downloads latest safe-upgrade from LibreMesh repository
2. Creates backup of router configuration
3. Transfers safe-upgrade using legacy SSH/SCP compatibility
4. Executes firmware upgrade safely
5. Waits for reboot and verifies completion

### Manual safe-upgrade Update Only

If you only need to update the safe-upgrade script:

```bash
# Quick safe-upgrade update only
./scripts/utils/update-safe-upgrade.sh thisnode.info
```

### Manual Process (for reference)

**Step 1: Connect with legacy SSH**
```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info
```

**Step 2: Download safe-upgrade on PC**
```bash
wget -O safe-upgrade https://raw.githubusercontent.com/libremesh/lime-packages/refs/heads/master/packages/safe-upgrade/files/usr/sbin/safe-upgrade
chmod +x safe-upgrade
```

**Step 3: Transfer using SCP (not sftp)**
```bash
scp -oHostKeyAlgorithms=+ssh-rsa safe-upgrade root@thisnode.info:/tmp/
```

**Step 4: Install and run on router**
```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info
mv /tmp/safe-upgrade /usr/sbin/safe-upgrade
chmod +x /usr/sbin/safe-upgrade
safe-upgrade -n  # Non-interactive upgrade
```

### Common Issues and Solutions

**SSH Connection Rejected**
```
Unable to negotiate with router: no matching host key type found
```
*Solution*: Use legacy algorithm: `ssh -oHostKeyAlgorithms=+ssh-rsa`

**SCP/SFTP Not Working**
```
ash: /usr/libexec/sftp-server: not found
scp: Connection closed
```
*Solution*: Use SCP with legacy SSH options instead of SFTP

**Router Not Responding After Upgrade**
- Wait 5-10 minutes for complete reboot
- Check power connection
- Try factory reset if necessary (30-30-30 method)

**Backup Recovery**
If upgrade fails, restore from backup:
```bash
# Extract backup made by upgrade script
tar -xzf cache/router-upgrade/backups/router_backup_*.tar.gz
# Transfer back to router when accessible
```

### Prerequisites

- SSH client with legacy algorithm support
- SCP capability (part of OpenSSH)
- Internet connection for firmware download
- Router accessible on network

### Verification

After successful upgrade, verify with:
```bash
ssh root@thisnode.info "cat /etc/banner"
```

Should show updated LibreMesh version and build date.

