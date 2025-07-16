# LibreRouter R2 Support Integration

## Problem
Error: `CONFIG_TARGET_ramips_mt7621_DEVICE_librerouter_librerouter-r2=y not found enabled`

## Solution
Switch to javierbrk's repository with pre-applied R2 patches instead of manual patching.

## Changes Made

### 1. Repository Configuration
**File:** `configs/versions.conf`
```diff
-librerouteros=https://gitlab.com/librerouter/librerouteros.git|librerouter-1.5|origin
+librerouteros=https://gitlab.com/javierbrk/librerouteros.git|main-with-lr2-support|javierbrk
```

### 2. Build Script Paths
**File:** `repos/librerouteros/librerouteros_build.sh`
```diff
-lo:define_default_value OPENWRT_SRC_DIR "$HOME/Development/openwrt/"
+lo:define_default_value OPENWRT_SRC_DIR "$(dirname $(realpath ${BASH_SOURCE}))/openwrt/"

-lo:define_default_value LIBREROUTEROS_DIR "$HOME/Development/librerouteros/"
+lo:define_default_value LIBREROUTEROS_DIR "$(dirname $(realpath ${BASH_SOURCE}))"

-lo:define_default_value KCONFIG_UTILS_DIR "$HOME/Development/kconfig-utils/"
+lo:define_default_value KCONFIG_UTILS_DIR "/home/pablo/repos/lime-dev/repos/kconfig-utils/"
```

## Repository Switch
```bash
git remote add javierbrk https://gitlab.com/javierbrk/librerouteros.git
git fetch javierbrk
git checkout javierbrk/main-with-lr2-support
git remote set-url origin https://gitlab.com/javierbrk/librerouteros.git
```

## Result
- New target available: `./librerouteros_build.sh librerouter-r2`
- Uses relative paths (more portable)
- OpenWrt source with R2 patches pre-applied
- No more kconfig fatal errors

## Custom Package Sources (Advanced)

For development with custom package forks, you can modify individual feed Makefiles:

### Example: Using Custom lime-app Fork
**File:** `repos/librerouteros/build/feeds/libremesh/packages/lime-app/Makefile`

```diff
-PKG_VERSION:=v0.2.27
-PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
-PKG_HASH:=c2b19242166d8cdce487d68622fcf1d2857053059a3f47b51417754161f8b57c
-PKG_SOURCE_URL:=https://github.com/Fede654/lime-app/releases/download/$(PKG_VERSION)
+PKG_VERSION:=master
+PKG_SOURCE_PROTO:=git
+PKG_SOURCE_URL:=https://github.com/Pablomonte/lime-app.git
+PKG_SOURCE_VERSION:=HEAD
+PKG_MIRROR_HASH:=skip
```

**Benefits:**
- Uses latest commits instead of fixed tags
- Points to your personal fork
- Enables rapid development iteration

**Note:** This change is temporary and may be overwritten when feeds are updated.

## Files Modified
1. `configs/versions.conf` - Repository source update
2. `librerouteros_build.sh` - Path fixes for portability
3. `build/feeds/libremesh/packages/lime-app/Makefile` - Custom package source (optional)