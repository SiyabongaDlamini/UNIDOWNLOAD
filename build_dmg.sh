#!/bin/bash
# Build script for Unidown DMG
# Run this from the yt_download directory

set -e

APP_NAME="Unidown"
DMG_FINAL="${APP_NAME}-1.0.0.dmg"
DMG_TEMP="${APP_NAME}-temp.dmg"
STAGING="dmg_staging"
VOL_NAME="${APP_NAME}"

echo "🔨 Step 1: Compiling Swift source..."
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"
cp Info.plist "${APP_NAME}.app/Contents/"
cp AppIcon.icns "${APP_NAME}.app/Contents/Resources/"
swiftc -O -framework Cocoa \
    -o "${APP_NAME}.app/Contents/MacOS/${APP_NAME}" \
    Unidown.swift

echo "📦 Step 2: Preparing DMG staging..."
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -R "${APP_NAME}.app" "${STAGING}/"
ln -sf /Applications "${STAGING}/Applications"

echo "💿 Step 3: Creating DMG..."
rm -f "${DMG_TEMP}" "${DMG_FINAL}"
hdiutil create \
    -srcfolder "${STAGING}" \
    -volname "${VOL_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 20m \
    "${DMG_TEMP}"

MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP}" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')
echo "   Mounted at: ${MOUNT_DIR}"

echo "🎨 Step 4: Styling DMG window..."
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "${VOL_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 150, 740, 450}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 112
        set position of item "${APP_NAME}.app" of container window to {140, 140}
        set position of item "Applications" of container window to {400, 140}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "${MOUNT_DIR}" -quiet

echo "🗜️  Step 5: Compressing final DMG..."
hdiutil convert "${DMG_TEMP}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_FINAL}"

rm -f "${DMG_TEMP}"
rm -rf "${STAGING}"

echo ""
echo "✅ Done! Your distributable DMG is ready:"
echo "   📀 $(pwd)/${DMG_FINAL}"
echo "   📏 Size: $(du -h "${DMG_FINAL}" | cut -f1)"
echo ""
echo "Share this file on GitHub, your website, or anywhere else!"
