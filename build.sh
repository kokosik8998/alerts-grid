#!/bin/bash
# Збирає AlertsGrid.app із AlertsGrid.swift (потрібен лише Xcode Command Line Tools).
set -e
cd "$(dirname "$0")"

APP="AlertsGrid.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Іконка (якщо є)
if [ -f AppIcon.icns ]; then
  cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>AlertsGrid</string>
  <key>CFBundleDisplayName</key><string>Карти тривог</string>
  <key>CFBundleIdentifier</key><string>com.kokosik.alertsgrid</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleExecutable</key><string>AlertsGrid</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <!-- дозволити http://map.war-monitor.org (не-https) -->
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
</dict>
</plist>
PLIST

swiftc -O AlertsGrid.swift -o "$APP/Contents/MacOS/AlertsGrid"
codesign --force --deep --sign - "$APP" 2>/dev/null || true

echo "Готово: $(pwd)/$APP"
