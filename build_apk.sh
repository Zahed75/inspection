#!/bin/bash
set -euo pipefail

# Always run from this script's directory (project root expected)
cd "$(dirname "$0")"

PUBSPEC_FILE="pubspec.yaml"
ANDROID_DIR="android"
LOCAL_PROPERTIES="$ANDROID_DIR/local.properties"

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

# Update local.properties with new version code
if grep -q "flutter.versionCode" "$LOCAL_PROPERTIES"; then
 if sed --version >/dev/null 2>&1; then
   sed -i "s/^flutter.versionCode=.*/flutter.versionCode=${BUILD_NUMBER}/" "$LOCAL_PROPERTIES"
 else
   sed -i '' "s/^flutter.versionCode=.*/flutter.versionCode=${BUILD_NUMBER}/" "$LOCAL_PROPERTIES"
 fi
else
 echo "flutter.versionCode=${BUILD_NUMBER}" >> "$LOCAL_PROPERTIES"
fi
echo "✅ local.properties updated: versionCode: ${BUILD_NUMBER}"

echo "🧹 Cleaning project..."
flutter clean
rm -rf "$ANDROID_DIR/build"
rm -rf "$ANDROID_DIR/app/build"

echo "📦 Getting dependencies..."
flutter pub get

echo "🔐 Verifying keystore configuration..."
# Check if keystore exists
KEYSTORE_PATH=$(grep "KEYSTORE_PATH" "$LOCAL_PROPERTIES" | cut -d'=' -f2)
if [[ -z "$KEYSTORE_PATH" ]]; then
  echo "❌ KEYSTORE_PATH not found in local.properties"
  exit 1
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "❌ Keystore file not found at: $KEYSTORE_PATH"
  echo "   Please check the path in local.properties"
  exit 1
fi
echo "✅ Keystore found: $KEYSTORE_PATH"

echo "🚀 Building signed APK using Gradle..."
cd "$ANDROID_DIR"

# Build the APK using Gradle directly (ensures proper signing)
./gradlew clean
./gradlew assembleRelease

cd ..

echo "🔍 Verifying APK signature..."
APK_PATH="build/app/outputs/apk/release/app-release.apk"

if [[ ! -f "$APK_PATH" ]]; then
  echo "❌ APK not found at expected path: $APK_PATH"
  echo "   Trying alternative path..."
  APK_PATH="android/app/build/outputs/apk/release/app-release.apk"
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "❌ APK not found at: $APK_PATH"
  echo "   Build may have failed. Check Gradle output above."
  exit 1
fi

# Verify the APK is properly signed
if command -v apksigner >/dev/null 2>&1; then
  if apksigner verify --print-certs "$APK_PATH"; then
    echo "✅ APK is properly signed"
  else
    echo "❌ APK signature verification failed!"
    echo "   The APK may not be properly signed."
    exit 1
  fi
else
  echo "⚠️  apksigner not available, skipping signature verification"
fi

# Copy to final location with version number
FINAL_APK="build/app/outputs/flutter-apk/survey-v-${BUILD_NUMBER}.apk"
mkdir -p "$(dirname "$FINAL_APK")"
cp -f "$APK_PATH" "$FINAL_APK"

echo "✅ Build complete:"
echo "   - Version: $NEW_VERSION"
echo "   - Version Code: $BUILD_NUMBER"
echo "   - APK: $FINAL_APK"
echo "   - File size: $(du -h "$FINAL_APK" | cut -f1)"

# Verify the APK can be read
echo "📦 Checking APK package info..."
if command -v aapt >/dev/null 2>&1; then
  PACKAGE_INFO=$(aapt dump badging "$FINAL_APK" 2>/dev/null | grep -E "(package|versionCode|versionName)" || true)
  if [[ -n "$PACKAGE_INFO" ]]; then
    echo "✅ APK package info:"
    echo "$PACKAGE_INFO" | while read -r line; do
      echo "   - $line"
    done
  else
    echo "⚠️  Could not read APK package info"
  fi
fi

# Try to open the folder (Linux/macOS)
( command -v xdg-open >/dev/null && xdg-open "$(dirname "$FINAL_APK")" ) \
 || ( command -v open >/dev/null && open "$(dirname "$FINAL_APK")" ) \
 || true

echo "🎉 Build process completed successfully!"