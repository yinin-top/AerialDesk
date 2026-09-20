#!/bin/bash
# Build AerialDesk.app into dist/
#   ./build.sh               native-arch build (fast, incremental)
#   ./build.sh --universal   arm64+x86_64 universal build (clean cache; used by CI)
set -euo pipefail
cd "$(dirname "$0")"

# Pin the Xcode toolchain: the CLT toolchain chokes on .build state produced here
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

VERSION=$(git describe --tags --always 2>/dev/null || echo "1.0.0")

BIN=""
if [ "${1:-}" = "--universal" ]; then
  # xcbuild state doesn't survive switches between native and cross builds — start clean
  rm -rf .build
  if swift build -c release --arch arm64 --arch x86_64; then
    # universal product lands in .build/out (xcbuild) or .build/apple (SwiftPM native)
    BIN=$(ls .build/out/Products/Release/AerialDesk .build/apple/Products/Release/AerialDesk 2>/dev/null | head -1 || true)
  fi
fi
if [ -z "$BIN" ]; then
  swift build -c release
  BIN=.build/release/AerialDesk
fi

APP=dist/AerialDesk.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/AerialDesk"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>AerialDesk</string>
    <key>CFBundleIdentifier</key><string>app.aerialdesk.AerialDesk</string>
    <key>CFBundleName</key><string>AerialDesk</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
EOF

codesign --force -s - "$APP"
echo "Built: $APP ($VERSION)"
