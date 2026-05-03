#!/usr/bin/env bash
set -euo pipefail

APP_PATH="build/DerivedData/Build/Products/Release/TakeABreak.app"
VOL_NAME="TakeABreak"
TEMP_DMG="build/TakeABreak_rw.dmg"
FINAL_DMG="TakeABreak.dmg"

echo "→ Cleaning up..."
rm -f "$FINAL_DMG" "$TEMP_DMG"
hdiutil detach "/Volumes/$VOL_NAME" 2>/dev/null || true

echo "→ Creating read-write DMG..."
hdiutil create -volname "$VOL_NAME" -fs HFS+ -megabytes 200 "$TEMP_DMG"

echo "→ Mounting..."
hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG"
sleep 2

MOUNT="/Volumes/$VOL_NAME"

echo "→ Copying app..."
cp -r "$APP_PATH" "$MOUNT/"
ln -s /Applications "$MOUNT/Applications"

echo "→ Configuring Finder window..."
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- compact window: 460 wide × 260 tall
        set the bounds of container window to {300, 150, 760, 410}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        -- app on left, Applications alias on right, vertically centred
        set position of item "TakeABreak.app" of container window to {120, 130}
        set position of item "Applications" of container window to {340, 130}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
APPLESCRIPT

echo "→ Syncing and detaching..."
sync
sleep 2
hdiutil detach "/Volumes/$VOL_NAME"

echo "→ Converting to read-only compressed DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

rm -f "$TEMP_DMG"
echo "✓ Done: $FINAL_DMG"
