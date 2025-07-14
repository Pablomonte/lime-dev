#!/bin/bash
#
# LibreRouterOS Build Wrapper
# Sets up proper environment for lime-build repository structure
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIME_BUILD_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIBREROUTEROS_DIR="$LIME_BUILD_DIR/repos/librerouteros"
LIME_APP_DIR="$LIME_BUILD_DIR/repos/lime-app"

# Function to prepare local lime-app
prepare_local_lime_app() {
    echo "Preparing local lime-app for build..."
    
    # Check if local lime-app exists
    if [[ ! -d "$LIME_APP_DIR" ]]; then
        echo "Error: Local lime-app directory not found at $LIME_APP_DIR"
        exit 1
    fi
    
    # Check if package.json exists
    if [[ ! -f "$LIME_APP_DIR/package.json" ]]; then
        echo "Error: lime-app package.json not found"
        exit 1
    fi
    
    echo "  Local lime-app: $LIME_APP_DIR"
    
    # Go to lime-app directory
    cd "$LIME_APP_DIR"
    
    # Check if node_modules exists, if not install dependencies
    if [[ ! -d "node_modules" ]]; then
        echo "  Installing dependencies..."
        npm install
    fi
    
    # Build lime-app
    echo "  Building lime-app..."
    npm run build
    
    # Verify build directory was created
    if [[ ! -d "build" ]]; then
        echo "Error: lime-app build failed - build directory not found"
        exit 1
    fi
    
    echo "  lime-app build completed successfully"
    
    # Go back to librerouteros directory
    cd "$LIBREROUTEROS_DIR"
    
    # Create temporary modified Makefile for lime-app package
    local lime_app_makefile="$LIBREROUTEROS_DIR/build/feeds/libremesh/packages/lime-app/Makefile"
    if [[ -f "$lime_app_makefile" ]]; then
        echo "  Backing up original Makefile..."
        cp "$lime_app_makefile" "$lime_app_makefile.backup"
        
        echo "  Creating local lime-app Makefile..."
        cat > "$lime_app_makefile" << 'EOF'
#
# Copyright (C) Libremesh 2017
#
# This is free software, licensed under the GNU General Public License v3.

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=local-dev
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LibreMesh
	TITLE:=LimeApp (Local Development Build)
	MAINTAINER:=German Ferrero <germanferrero@altermundi.net>
	URL:=http://github.com/libremesh/lime-app
	DEPENDS:=+rpcd +uhttpd +uhttpd-mod-ubus +uhttpd-mod-lua \
		+ubus-lime-location +ubus-lime-metrics +ubus-lime-utils \
		+rpcd-mod-iwinfo +ubus-lime-groundrouting
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Light webApp for LibreMesh over uhttpd (Local Development Build)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) LOCAL_LIME_APP_PATH/build/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
	$(INSTALL_DIR) $(1)/www/app/
	$(CP) $(PKG_BUILD_DIR)/* $(1)/www/app/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] ||	( /etc/init.d/rpcd restart && /etc/init.d/uhttpd restart ) || true
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
EOF
        
        # Replace placeholder with actual path
        sed -i "s|LOCAL_LIME_APP_PATH|$LIME_APP_DIR|g" "$lime_app_makefile"
        
        echo "  Local lime-app Makefile created"
    else
        echo "Warning: lime-app Makefile not found at $lime_app_makefile"
        echo "You may need to run 'make menuconfig' and enable lime-app first"
    fi
}

# Function to restore original lime-app Makefile
restore_lime_app_makefile() {
    local lime_app_makefile="$LIBREROUTEROS_DIR/build/feeds/libremesh/packages/lime-app/Makefile"
    if [[ -f "$lime_app_makefile.backup" ]]; then
        echo "Restoring original lime-app Makefile..."
        mv "$lime_app_makefile.backup" "$lime_app_makefile"
    fi
}

# Check if we're in the right place
if [[ ! -f "$LIBREROUTEROS_DIR/librerouteros_build.sh" ]]; then
    echo "Error: LibreRouterOS build script not found"
    echo "Expected: $LIBREROUTEROS_DIR/librerouteros_build.sh"
    exit 1
fi

cd "$LIBREROUTEROS_DIR"

# Set up environment for our repository structure
export OPENWRT_SRC_DIR="$LIBREROUTEROS_DIR/openwrt/"
export KCONFIG_UTILS_DIR="$LIME_BUILD_DIR/repos/kconfig-utils/"
export LIBREROUTEROS_DIR="$LIBREROUTEROS_DIR"

# Override other paths to be relative to our build structure
export OPENWRT_DL_DIR="$LIBREROUTEROS_DIR/dl/"
export LIBREROUTEROS_BUILD_DIR="$LIBREROUTEROS_DIR/build/"

# Ensure necessary directories exist
mkdir -p "$OPENWRT_DL_DIR"
mkdir -p "$LIBREROUTEROS_BUILD_DIR"

echo "LibreRouterOS Build Wrapper"
echo "  OpenWrt source: $OPENWRT_SRC_DIR"
echo "  Kconfig utils: $KCONFIG_UTILS_DIR"
echo "  Download dir: $OPENWRT_DL_DIR"
echo "  Build dir: $LIBREROUTEROS_BUILD_DIR"
echo "  Target: ${1:-librerouter-v1}"

# Check if LOCAL_LIME_APP is set
if [[ "$LOCAL_LIME_APP" == "true" ]]; then
    echo "  Using local lime-app: $LIME_APP_DIR"
fi

echo ""

# Check if kconfig-utils is available
if [[ ! -f "$KCONFIG_UTILS_DIR/kconfig-utils.sh" ]]; then
    echo "Error: kconfig-utils.sh not found at $KCONFIG_UTILS_DIR"
    echo "Make sure repos are properly cloned with setup-lime-dev.sh"
    exit 1
fi

# Check if OpenWrt source is available
if [[ ! -d "$OPENWRT_SRC_DIR" ]]; then
    echo "Error: OpenWrt source not found at $OPENWRT_SRC_DIR"
    echo "Make sure repos are properly cloned with setup-lime-dev.sh"
    exit 1
fi

# Prepare local lime-app if requested
if [[ "$LOCAL_LIME_APP" == "true" ]]; then
    prepare_local_lime_app
fi

# Set up cleanup trap to restore original Makefile
if [[ "$LOCAL_LIME_APP" == "true" ]]; then
    trap 'restore_lime_app_makefile' EXIT INT TERM
fi

# Run the original LibreRouterOS build script
exec ./librerouteros_build.sh "$@"