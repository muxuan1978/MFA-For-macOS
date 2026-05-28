#!/bin/bash
set -e

cd /opt/develop/tools/MFA

echo "Building..."
xcodebuild build \
  -project MFA.xcodeproj \
  -scheme MFA \
  -configuration Debug \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  2>&1 | tail -3

APP="build/Build/Products/Debug/MFA.app"
PLIST="$APP/Contents/Info.plist"

echo "Injecting Info.plist keys..."
plutil -replace NSCameraUsageDescription -string "MFA needs camera access to scan QR codes for adding accounts." "$PLIST"
plutil -replace LSUIElement -bool true "$PLIST"
plutil -replace NSSupportsAutomaticTermination -bool true "$PLIST"
plutil -replace NSSupportsSuddenTermination -bool true "$PLIST"

echo "Re-signing..."
codesign --force --sign - --entitlements Resources/MFA.entitlements "$APP"

echo "Verifying..."
plutil -p "$PLIST" | grep -E '(Camera|LSUIElement)'

echo "Done! App at: $APP"
