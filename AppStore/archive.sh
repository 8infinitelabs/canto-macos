#!/bin/bash
# Canto — App Store Archive Script
# Usage: ./AppStore/archive.sh
#
# Prerequisites:
#   1. Apple Developer account with App Store Connect access
#   2. Xcode Cloud or local signing certificate
#   3. App record created in App Store Connect (com.infinitelabs.canto)
#   4. App Store Connect API key configured (optional, for upload)

set -euo pipefail

APP_NAME="Canto"
PROJECT="Canto.xcodeproj"
SCHEME="Canto"
ARCHIVE_PATH="./build/Canto.xcarchive"
EXPORT_PATH="./build/AppStore"

echo "=== Canto App Store Build ==="
echo ""

# Step 1: Clean
echo "[1/4] Cleaning..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" clean 2>&1 | tail -1

# Step 2: Bump build number (optional)
BUILD_NUMBER=$(date +%Y%m%d%H%M)
# Uncomment below to auto-bump build number:
# /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "Canto/Info.plist"

# Step 3: Archive
echo "[2/4] Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Manual \
    2>&1 | grep -E "(Archive|error:|BUILD)"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "ERROR: Archive failed. Check signing settings in Xcode."
    exit 1
fi

echo "[3/4] Archive created at $ARCHIVE_PATH"

# Step 4: Validate & Export
echo "[4/4] Exporting App Store build..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "AppStore/exportOptions.plist" \
    2>&1 | grep -E "(export|error:|succeeded)"

if [ -d "$EXPORT_PATH" ]; then
    echo ""
    echo "=== Build ready for upload ==="
    echo "App: $EXPORT_PATH/$APP_NAME.app"
    echo ""
    echo "Next steps:"
    echo "  1. Test the exported build: open $EXPORT_PATH"
    echo "  2. Upload via Transporter: xcrun altool --upload-app ..."
    echo "  3. Or use Xcode: open Xcode > Window > Organizer > Distribute App"
else
    echo "Export failed. Check signing and try using Xcode Organizer directly."
    echo "  open Xcode > Window > Organizer > Archives > Distribute App"
fi
