#!/bin/bash
set -euo pipefail

# Always run from this script's directory (project root expected)
cd "$(dirname "$0")"

PUBSPEC_FILE="pubspec.yaml"

echo "🔧 Bumping build number..."

# Read current version line
CURRENT_VERSION_LINE=$(grep -E '^version:' "$PUBSPEC_FILE")
CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | awk '{print $2}')
VERSION_NAME="${CURRENT_VERSION%%+*}"
BUILD_NUMBER="${CURRENT_VERSION#*+}"
if [[ "$BUILD_NUMBER" == "$CURRENT_VERSION" ]]; then
 BUILD_NUMBER=0
fi
BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${VERSION_NAME}+${BUILD_NUMBER}"

# Portable in-place sed (macOS vs Linux)
if sed --version >/dev/null 2>&1; then
 # GNU sed (Linux)
 sed -i "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC_FILE"
else
 # BSD sed (macOS)
 sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" "$PUBSPEC_FILE"
fi
echo "✅ pubspec.yaml updated: version: ${NEW_VERSION}"

echo "🧹 flutter clean..."
flutter clean
echo "📦 flutter pub get..."
flutter pub get

echo "🚀 Building universal APK..."
flutter build apk --release \
 --target-platform=android-arm,android-arm64,android-x64

# Common output paths
UNIVERSAL_APK="build/app/outputs/flutter-apk/app-release.apk"
VERSIONED_APK="build/app/outputs/flutter-apk/app-${VERSION_NAME}+${BUILD_NUMBER}.apk"

OUT_APK=""
if [[ -f "$VERSIONED_APK" ]]; then
 OUT_APK="$VERSIONED_APK"
elif [[ -f "$UNIVERSAL_APK" ]]; then
 OUT_APK="$UNIVERSAL_APK"
else
 echo "❌ Could not find built APK. Check your Gradle rename step."
 exit 1
fi

FINAL_APK="build/app/outputs/flutter-apk/survey-v-${BUILD_NUMBER}.apk"
cp -f "$OUT_APK" "$FINAL_APK"

echo "✅ Build complete:"
echo "   - Version: $NEW_VERSION"
echo "   - APK: $FINAL_APK"

# Try to open the folder (Linux/macOS)
( command -v xdg-open >/dev/null && xdg-open "$(dirname "$FINAL_APK")" ) \
 || ( command -v open >/dev/null && open "$(dirname "$FINAL_APK")" ) \
 || true
