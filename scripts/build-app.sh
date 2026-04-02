#!/bin/bash
set -e

BINARY=".build/release/ClawWatch"
APP_DIR="ClawWatch.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Build
swift build -c release

# Assemble bundle
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BINARY" "$MACOS/ClawWatch"

# Copy icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

# Write Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>   <string>ClawWatch</string>
  <key>CFBundleIdentifier</key>   <string>com.local.clawwatch</string>
  <key>CFBundleName</key>         <string>ClawWatch</string>
  <key>CFBundleVersion</key>      <string>2.0</string>
  <key>CFBundleIconFile</key>     <string>AppIcon</string>
  <key>LSUIElement</key>          <true/>
  <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "✓ Built: $APP_DIR"
echo "  Install: cp -r $APP_DIR /Applications/"
