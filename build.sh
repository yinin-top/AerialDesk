#!/bin/bash
# Build AerialDesk.app into dist/
#   ./build.sh               native-arch build (fast, incremental)
#   ./build.sh --universal   arm64+x86_64 universal build (used by CI releases)
set -euo pipefail
cd "$(dirname "$0")"

# Pin the Xcode toolchain: the CLT toolchain's xcbuild session fails to init here
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

VERSION=$(git describe --tags --always 2>/dev/null || echo "1.0.0")

BIN=""
if [ "${1:-}" = "--universal" ]; then
  # Build each arch into its own scratch dir, then lipo-merge. Deterministic across
  # SwiftPM versions (the --arch pair shortcut behaves differently on some toolchains).
  swift build -c release --triple arm64-apple-macosx --scratch-path .build/arm64
  swift build -c release --triple x86_64-apple-macosx --scratch-path .build/x86_64
  ARM=$(find .build/arm64 -type f -name AerialDesk | head -1)
  X86=$(find .build/x86_64 -type f -name AerialDesk | head -1)
  [ -n "$ARM" ] && [ -n "$X86" ] || { echo "universal build: missing arch binaries" >&2; exit 1; }
  mkdir -p dist
  lipo -create "$ARM" "$X86" -output dist/AerialDesk-universal
  # Fail loudly rather than silently shipping a single-arch binary
  lipo -info dist/AerialDesk-universal | grep -q x86_64 && lipo -info dist/AerialDesk-universal | grep -q arm64
  BIN=dist/AerialDesk-universal
fi
if [ -z "$BIN" ]; then
  swift build -c release || { rm -rf .build; swift build -c release; }   # self-heal poisoned .build state
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
lipo -info "$APP/Contents/MacOS/AerialDesk"
