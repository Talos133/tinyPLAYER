#!/usr/bin/env bash
# run.sh — Build tinyPLAYER and launch it directly without installing.
# Useful for quick iteration; the app runs from the build output folder.
#
# Requirements: Xcode command-line tools (xcode-select --install)
# Usage:  bash scripts/run.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="tinyPLAYER"
ENTITLEMENTS="$PROJECT_DIR/tinyPLAYER/tinyPLAYER.local.entitlements"
BUILD_DIR="$PROJECT_DIR/.build-local"
APP_NAME="tinyPLAYER.app"

echo "=== tinyPLAYER run ==="

# ── 1. Build ─────────────────────────────────────────────────────────────────
echo "Building..."
xcodebuild build \
  -scheme "$SCHEME" \
  -configuration Debug \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | grep -E '(error:|BUILD (SUCCEEDED|FAILED))' || true

APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "$APP_NAME" 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  APP_PATH=$(find "$BUILD_DIR" -name "$APP_NAME" 2>/dev/null | head -1)
fi
if [ -z "$APP_PATH" ]; then
  echo "ERROR: $APP_NAME not found — build may have failed"
  exit 1
fi

# ── 2. Ad-hoc sign ───────────────────────────────────────────────────────────
codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  "$APP_PATH" 2>/dev/null

# ── 3. Remove quarantine ─────────────────────────────────────────────────────
xattr -cr "$APP_PATH" 2>/dev/null || true

# ── 4. Launch ────────────────────────────────────────────────────────────────
echo "Launching $APP_PATH"
open "$APP_PATH"
