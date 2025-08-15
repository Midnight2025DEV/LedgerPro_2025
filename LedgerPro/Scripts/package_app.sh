#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=== Packaging LedgerPro for Distribution ==="

# Build backend
echo "Building backend..."
"$SCRIPT_DIR/build_backend.sh"

# Build Swift app
echo "Building Swift app..."
cd "$PROJECT_ROOT"
swift build -c release

# Create app bundle structure
APP_NAME="LedgerPro"
BUILD_DIR="$PROJECT_ROOT/.build/release"
APP_BUNDLE="$PROJECT_ROOT/$APP_NAME.app"

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/LedgerPro" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy backend
cp "$PROJECT_ROOT/Resources/ledgerpro-backend" "$APP_BUNDLE/Contents/Resources/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.ledgerpro.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Create DMG
echo "Creating DMG..."
DMG_NAME="$PROJECT_ROOT/LedgerPro-1.0.0.dmg"
rm -f "$DMG_NAME"

# Create a temporary directory for DMG contents
DMG_TEMP="$PROJECT_ROOT/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create symbolic link to Applications
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf "$DMG_TEMP"

echo "=== Packaging complete! ==="
echo "App bundle: $APP_BUNDLE"
echo "DMG: $DMG_NAME"
echo ""
echo "To install: Open the DMG and drag LedgerPro to Applications"