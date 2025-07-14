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
- No sftp-server support (SCP and SFTP both fail)
- Limited resources for direct firmware downloads
- Outdated safe-upgrade script

**Note**: Both SCP and SFTP fail with error: `ash: /usr/libexec/sftp-server: not found`

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
3. Transfers safe-upgrade using alternative methods (no SCP/SFTP required)
4. Executes firmware upgrade safely
5. Waits for reboot and verifies completion

**Transfer methods used (in order of preference):**
- HTTP server + wget (if router has wget)
- Base64 encoding via SSH  
- Hex encoding via SSH (for small files)
- Chunked transfer for large files

### Manual safe-upgrade Update Only

If you only need to update the safe-upgrade script:

```bash
# Quick safe-upgrade update only
./scripts/utils/update-safe-upgrade.sh thisnode.info
```

### Alternative File Transfer Methods

Since SCP/SFTP don't work on legacy routers, use these alternative methods:

#### Method 1: HTTP Server + wget (Recommended)
```bash
# 1. Start HTTP server on PC
cd /path/to/file/directory
python3 -m http.server 8765

# 2. Download on router (if wget available)
ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info
wget -O /tmp/safe-upgrade http://YOUR_PC_IP:8765/safe-upgrade
```

#### Method 2: Base64 Encoding via SSH
```bash
# 1. Encode file on PC
base64 safe-upgrade > safe-upgrade.b64

# 2. Transfer and decode on router
ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info
cat > /tmp/safe-upgrade.b64
# Paste base64 content, then Ctrl+D

base64 -d /tmp/safe-upgrade.b64 > /tmp/safe-upgrade
rm /tmp/safe-upgrade.b64
```

#### Method 3: Automated Transfer Script
```bash
# Use the automated transfer script
./scripts/transfer-to-legacy-router.sh thisnode.info safe-upgrade /usr/sbin/safe-upgrade
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

**Step 3: Transfer using alternative methods**
Use one of the methods described above (HTTP, base64, or transfer script)

**Step 4: Install and run on router**
```bash
ssh -oHostKeyAlgorithms=+ssh-rsa root@thisnode.info
chmod +x /tmp/safe-upgrade
mv /tmp/safe-upgrade /usr/sbin/safe-upgrade
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
*Solution*: Both SCP and SFTP fail on legacy routers. Use alternative transfer methods:
- HTTP server + wget (recommended)
- Base64 encoding via SSH
- Automated transfer script: `./scripts/transfer-to-legacy-router.sh`

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

