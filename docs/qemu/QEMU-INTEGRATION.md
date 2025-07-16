# 🖥️ QEMU LibreMesh Integration Guide

## 🎯 Purpose

This guide describes the persistent QEMU LibreMesh testing environment integrated with the lime-dev development workflow. Enables authenticated testing against a real LibreMesh backend running in QEMU.

**Integration with development stack:**
- Compatible with lime-dev QEMU management scripts
- Optimized for development and testing workflows
- Part of the comprehensive LibreMesh testing framework

## Quick Start

```bash
# 1. Complete environment verification (includes QEMU)
./tools/verify/setup.sh

# 2. Start QEMU LibreMesh
./tools/qemu/qemu-manager.sh start

# 3. Test with QEMU integration
./tools/qemu/test-with-qemu.sh all

# 4. Development with real backend
./tools/qemu/dev-with-qemu.sh
```

## Architecture

### System Components

1. **QEMU LibreMesh**: Authentic LibreMesh instance in virtual environment
2. **Authentication System**: Automated login and session management
3. **Test Infrastructure**: Real backend integration for testing
4. **Persistent Configuration**: Reusable setup for accelerated testing cycles

### Network Configuration

- **QEMU IP**: `10.13.0.1`
- **Web Interface**: `http://10.13.0.1/app/`
- **ubus Endpoint**: `http://10.13.0.1/ubus`
- **Credentials**: `root/admin` (configured by setup script)

## Setup Details

### 1. Persistent Configuration

The setup script creates persistent configuration in `/tmp/qemu-lime-persistent/`:

```
/tmp/qemu-lime-persistent/
├── start-qemu.sh              # QEMU startup script
├── configure-qemu.sh          # QEMU configuration script
└── lime-app-build/            # Saved build for quick deployment
```

### 2. Authentication Flow

```javascript
// Automatic authentication with session management
import QemuAuth from './qemu-auth-helpers';

// Get authenticated session (auto-login)
const session = await QemuAuth.getAuthenticatedSession();

// Make authenticated ubus calls
const systemInfo = await QemuAuth.ubusCall('system', 'info');

// Test specific services
const tmateStatus = await QemuAuth.testTmateService();
```

### 3. Test Structure

```javascript
// Authenticated integration test example
describe("Integration Tests", () => {
    QemuTestUtils.setupAuthenticatedTests();

    (skipIfNoQemu ? it.skip : it)("should test real backend", async () => {
        const result = await QemuAuth.ubusCall('system', 'board');
        expect(result).toBeDefined();
    });
});
```

## Available Scripts

```bash
# QEMU Management
./tools/qemu/qemu-manager.sh start    # Start QEMU
./tools/qemu/qemu-manager.sh stop     # Stop QEMU
./tools/qemu/qemu-manager.sh status   # Check status

# Development
./tools/qemu/dev-with-qemu.sh         # Development server with QEMU backend
./tools/qemu/deploy-to-qemu.sh        # Deploy application to QEMU

# Testing
./tools/qemu/test-with-qemu.sh unit        # Unit tests only
./tools/qemu/test-with-qemu.sh integration # Integration tests
./tools/qemu/test-with-qemu.sh all         # All tests

# Verification
./tools/qemu/verify-qemu.sh           # Complete environment verification
```

## QEMU Management

### Starting QEMU

```bash
# If QEMU is not running
./tools/qemu/qemu-manager.sh start

# With specific configuration
QEMU_IMAGE_CONFIG=libremesh-2305 ./tools/qemu/qemu-manager.sh start
```

### Console Access

```bash
# Access QEMU console
screen -r libremesh

# Or check for running sessions
screen -list
```

### Configuration Commands

```bash
# Set root password
echo -e 'admin\nadmin' | passwd root

# Configure network
ip addr add 10.13.0.1/16 dev br-lan

# Start web server
/etc/init.d/uhttpd restart
```

## Testing Workflow

### 1. Development Testing

```bash
# Start development server with QEMU backend
./tools/qemu/dev-with-qemu.sh

# Access development at: http://localhost:8080
# Access QEMU at: http://10.13.0.1
```

### 2. Quick Testing

```bash
# Test without rebuilding
./tools/qemu/test-with-qemu.sh integration

# Test specific pattern
./tools/qemu/test-with-qemu.sh pattern remotesupport
```

### 3. Full Integration Testing

```bash
# Complete test suite with QEMU
./tools/qemu/test-with-qemu.sh all

# Includes: setup → build → deploy → test → verify
```

## Available Services in QEMU

The QEMU LibreMesh instance provides these ubus services:

- **tmate**: Remote support functionality ✅
- **system**: System information and control ✅
- **session**: Authentication and session management ✅
- **shared-state**: Mesh-wide state synchronization ✅
- **pirania**: Captive portal system ✅
- **network**: Network interface management ✅
- **wireless-service**: WiFi management ✅

## Authentication Details

### Account Types & Usage Scenarios

LibreMesh supports two distinct authentication models:

#### 1. Development/QEMU Authentication
**Account:** `root` / **Password:** `admin`
- **Purpose**: QEMU development environment only
- **Access Level**: Full administrative access to all features
- **Protected Routes**: Can access firmware, node configuration, etc.
- **Usage**: Development, testing, debugging

#### 2. Production LibreMesh Authentication
**Account:** `lime-app` / **Password:** (empty)
- **Purpose**: Production LibreMesh deployments
- **Access Level**: Basic user access to public features
- **Protected Routes**: Limited access to configuration features
- **Usage**: End-user mesh network management

### Authentication Implementation

```javascript
// Development/Testing (QEMU)
const devSession = await QemuAuth.getAuthenticatedSession();
// Uses root/admin credentials automatically

// Production (Real LibreMesh)
const prodAuth = {
    username: "lime-app",
    password: ""
};
```

## Performance Considerations

### 1. Persistent Setup Benefits

- **18x faster startup**: Persistent configuration eliminates rebuild time
- **Instant deployment**: Pre-configured environment ready immediately
- **Consistent state**: Reproducible testing environment

### 2. Development Optimization

```bash
# Fast development cycle
./tools/qemu/qemu-manager.sh start     # 5 seconds (persistent)
./tools/qemu/deploy-to-qemu.sh         # 2 seconds (deploy only)
# Total: 7 seconds vs 2+ minutes with full rebuild
```

## Troubleshooting

### Common Issues

#### QEMU Won't Start
```bash
# Check if QEMU is already running
pgrep -f qemu-system-x86_64

# Check TAP interfaces
./tools/qemu/qemu-dev-fix.sh
```

#### Network Connectivity Issues
```bash
# Test basic connectivity
ping 10.13.0.1

# Check web interface
curl -s http://10.13.0.1/

# Check ubus endpoint
curl -s http://10.13.0.1/ubus
```

#### Authentication Failures
```bash
# Test authentication manually
curl -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"call","params":["00000000000000000000000000000000","session","login",{"username":"root","password":"admin"}]}' \
  http://10.13.0.1/ubus
```

### Environment Verification

```bash
# Complete environment check
./tools/qemu/verify-qemu.sh

# This checks:
# - QEMU process status
# - Network connectivity
# - Web interface accessibility
# - ubus endpoint functionality
# - System services
```

## Integration with Testing

### 1. JavaScript Test Helpers

```javascript
// Available in tools/utils/
import QemuAuth from './qemu-auth-helpers';
import { QemuTestUtils } from './qemu-test-helpers';

// Setup authenticated tests
QemuTestUtils.setupAuthenticatedTests();

// Conditional testing
const skipIfNoQemu = !await QemuTestUtils.isAvailable();
```

### 2. Shell Test Integration

```bash
# Integration with existing test suites
if ./tools/qemu/verify-qemu.sh; then
    echo "QEMU available - running integration tests"
    ./tools/qemu/test-with-qemu.sh integration
else
    echo "QEMU not available - skipping integration tests"
fi
```

## Configuration Reference

### Environment Variables

```bash
# QEMU Configuration
QEMU_IMAGE_CONFIG=libremesh-2305     # Force specific configuration
QEMU_TEST=true                       # Enable QEMU integration tests
NODE_HOST=10.13.0.1                  # QEMU IP address

# Network Configuration
QEMU_IP="10.13.0.1"                 # QEMU LibreMesh IP
HOST_IP="10.13.0.2"                 # Host machine IP
TIMEOUT=5                            # Connection timeout
```

### Image Configurations

```bash
# Available configurations
libremesh-2305      # LibreMesh 23.05.5 (stable)
librerouteros-2410  # LibreRouterOS 24.10.1 (development)
```

## Best Practices

### 1. Development Workflow

1. **Start with verification**: Always run `./tools/qemu/verify-qemu.sh` first
2. **Use persistent setup**: Leverage existing configuration for faster cycles
3. **Test incrementally**: Use specific test patterns for focused testing
4. **Clean up properly**: Stop QEMU when done to free resources

### 2. Testing Strategy

1. **Unit tests first**: Test components in isolation
2. **Integration second**: Test with real backend when needed
3. **Authenticated last**: Test authenticated flows with real sessions
4. **Performance monitoring**: Track test execution times

### 3. Debugging Approach

1. **Layer by layer**: Test network → web → ubus → authentication
2. **Use console access**: Direct QEMU console for system debugging
3. **Log everything**: Enable verbose logging for complex issues
4. **Verify environment**: Always check complete setup first

---

## Summary

The QEMU LibreMesh integration provides a **complete development and testing environment** that supports:

1. **Authentic LibreMesh Backend** - Real ubus services and LibreMesh functionality
2. **Automated Authentication** - Session management and credential handling
3. **Persistent Configuration** - 18x faster testing cycles through saved state
4. **Complete Tool Integration** - Seamless integration with lime-dev toolchain

This environment enables **authentic testing** against real LibreMesh services while maintaining the **speed and convenience** of local development.