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
