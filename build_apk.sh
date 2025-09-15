#!/bin/bash
set -euo pipefail

# Always run from this script's directory (project root expected)
cd "$(dirname "$0")"

PUBSPEC_FILE="pubspec.yaml"
ANDROID_DIR="android"
LOCAL_PROPERTIES="$ANDROID_DIR/local.properties"

# Detect OS and set appropriate paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux paths
    KEYSTORE_PATH="${KEYSTORE_PATH:-/home/zahed/keystore/app-release.jks}"
    ANDROID_SDK="${ANDROID_SDK:-/home/zahed/Android/Sdk}"
    FLUTTER_SDK="${FLUTTER_SDK:-/home/zahed/tools/flutter}"
else
    # macOS paths (default)
    KEYSTORE_PATH="${KEYSTORE_PATH:-/Users/md.zahedhasanrabbi/keystore/app-release.jks}"
    ANDROID_SDK="${ANDROID_SDK:-/Users/md.zahedhasanrabbi/Library/Android/sdk}"
    FLUTTER_SDK="${FLUTTER_SDK:-/Users/tools/flutter}"
fi

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

# Create/update local.properties with OS-specific paths
cat > "$LOCAL_PROPERTIES" << EOF
sdk.dir=$ANDROID_SDK
flutter.sdk=$FLUTTER_SDK
KEYSTORE_PATH=$KEYSTORE_PATH
KEYSTORE_PASSWORD=ZahedACI123
KEY_ALIAS=app
KEY_PASSWORD=ZahedACI123
flutter.buildMode=release
flutter.versionName=$VERSION_NAME
flutter.versionCode=$BUILD_NUMBER
EOF

echo "✅ local.properties updated with OS-specific paths"

echo "🧹 Cleaning project..."
flutter clean
rm -rf "$ANDROID_DIR/build"
rm -rf "$ANDROID_DIR/app/build"

echo "📦 Getting dependencies..."
flutter pub get

echo "🔐 Verifying keystore configuration..."
# Check if keystore exists
if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "❌ Keystore file not found at: $KEYSTORE_PATH"
  echo "   Please copy your keystore to this location or update KEYSTORE_PATH"
  echo "   You can get it from your Mac at: /Users/md.zahedhasanrabbi/keystore/app-release.jks"
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
  echo "   Install it via: sudo apt install apksigner"
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
    echo "   Install aapt via: sudo apt install aapt"
  fi
else
  echo "⚠️  aapt not available, skipping package info check"
  echo "   Install it via: sudo apt install aapt"
fi

# Open the folder in file manager
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$(dirname "$FINAL_APK")" 2>/dev/null || true
fi

echo "🎉 Build process completed successfully!"