#!/bin/bash

# build_wireguard_go_bridge.sh
# Builds the wireguard-go-bridge C library required by WireGuardKit.
# Called by the WireGuardGoBridge External Build System target in Xcode.

set -euo pipefail

# Ensure Go is available
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v go &> /dev/null; then
    echo "error: Go is not installed. Run 'brew install go' and restart Xcode."
    exit 1
fi

echo "Using Go: $(go version)"

# --- Locate the wireguard-apple SPM checkout ---
# Strategy 1: Use Xcode's BUILD_DIR environment variable (set during builds)
if [ -n "${BUILD_DIR:-}" ]; then
    CHECKOUT="$(dirname "$(dirname "${BUILD_DIR}")")/SourcePackages/checkouts/wireguard-apple"
    if [ -d "$CHECKOUT" ]; then
        PACKAGES_DIR="$CHECKOUT"
    fi
fi

# Strategy 2: Search DerivedData for the project's SourcePackages
if [ -z "${PACKAGES_DIR:-}" ]; then
    PACKAGES_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "SafeMesh*" -maxdepth 1 -type d 2>/dev/null | while read dd; do
        checkout="$dd/SourcePackages/checkouts/wireguard-apple"
        if [ -d "$checkout" ]; then
            echo "$checkout"
            break
        fi
    done)
fi

# Strategy 3: Check if the package lives in the project directory (Xcode workspace)
if [ -z "${PACKAGES_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    
    # Check .swiftpm in project root
    if [ -d "$PROJECT_DIR/.swiftpm/checkouts/wireguard-apple" ]; then
        PACKAGES_DIR="$PROJECT_DIR/.swiftpm/checkouts/wireguard-apple"
    fi
fi

if [ -z "${PACKAGES_DIR:-}" ] || [ ! -d "${PACKAGES_DIR}" ]; then
    echo "warning: Cannot find wireguard-apple package checkout."
    echo "warning: This likely means Xcode hasn't resolved the SPM package yet."
    echo "warning: Steps to fix:"
    echo "warning:   1. In Xcode, go to File → Packages → Resolve Package Versions"
    echo "warning:   2. Wait for the package to download"
    echo "warning:   3. Build again"
    echo ""
    echo "warning: Skipping wireguard-go-bridge build for now (will fail at link time if needed)"
    exit 0
fi

echo "Found wireguard-apple at: $PACKAGES_DIR"

# Navigate to the Go bridge source
BRIDGE_DIR="$PACKAGES_DIR/Sources/WireGuardKitGo"

if [ ! -d "$BRIDGE_DIR" ]; then
    echo "error: Cannot find WireGuardKitGo at $BRIDGE_DIR"
    exit 1
fi

cd "$BRIDGE_DIR"

echo "Building wireguard-go-bridge..."
make

echo "wireguard-go-bridge built successfully"
