#!/usr/bin/env bash
# install.sh — Build tinyPLAYER and install to /Applications without a paid
# Apple Developer account. Uses ad-hoc signing with a minimal local entitlements
# file (no sandbox, no paid-team entitlements) so macOS does not reject the app
# as "damaged" and Gatekeeper does not block it.
#
# Requirements: Xcode command-line tools (xcode-select --install)
# Usage:  bash scripts/install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="tinyPLAYER"
ENTITLEMENTS="$PROJECT_DIR/tinyPLAYER/tinyPLAYER.local.entitlements"
BUILD_DIR="$PROJECT_DIR/.build-local"
APP_NAME="tinyPLAYER.app"
INSTALL_PATH="/Applications/$APP_NAME"

echo "=== tinyPLAYER install ==="
echo ""

# ── 1. Build ────────────────────────────────────────────────────────────────
echo "Building (Release)..."
xcodebuild build \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | grep -E '(error:|BUILD (SUCCEEDED|FAILED))' || true

# Find the compiled .app (search under Build/Products)
APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "$APP_NAME" 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME" 2>/dev/null | head -1)
fi
if [ -z "$APP_PATH" ]; then
  echo "ERROR: build succeeded but $APP_NAME was not found under $BUILD_DIR"
  exit 1
fi
echo "  Built: $APP_PATH"

# ── 2. Ad-hoc sign with local (no-sandbox) entitlements ─────────────────────
echo "Signing (ad-hoc)..."
codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  "$APP_PATH"

# ── 3. Remove quarantine flag so Gatekeeper does not block launch ────────────
echo "Removing quarantine..."
xattr -cr "$APP_PATH" 2>/dev/null || true

# ── 4. Install ───────────────────────────────────────────────────────────────
echo "Installing to $INSTALL_PATH..."
rm -rf "$INSTALL_PATH"
cp -r "$APP_PATH" "$INSTALL_PATH"
xattr -cr "$INSTALL_PATH" 2>/dev/null || true

echo ""
echo "=== Done! ==="
echo "Launch:  open '$INSTALL_PATH'"
echo "         (or double-click tinyPLAYER in Finder > Applications)"
echo ""
echo "First launch: macOS will ask for Apple Music access. Allow it."
echo "If it says the app is damaged, run:"
echo "  sudo xattr -cr '$INSTALL_PATH'"
