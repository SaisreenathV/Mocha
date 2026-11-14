#!/usr/bin/env bash
set -e

# Mocha AppImage Build Script
# Requirements: flutter, curl/wget, appimagetool

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "==> Building Flutter Linux release bundle..."
flutter build linux --release

APP_NAME="mocha"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
APPDIR="$PROJECT_ROOT/build/AppDir"

echo "==> Setting up AppDir structure at $APPDIR..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy Flutter bundle
cp -r "$BUILD_DIR/"* "$APPDIR/usr/bin/"

# Copy desktop file
cp "$PROJECT_ROOT/packaging/linux/mocha.desktop" "$APPDIR/usr/share/applications/$APP_NAME.desktop"
cp "$PROJECT_ROOT/packaging/linux/mocha.desktop" "$APPDIR/$APP_NAME.desktop"

# Copy / create icon placeholder if none exists
if [ -f "$PROJECT_ROOT/assets/icons/mocha.png" ]; then
    cp "$PROJECT_ROOT/assets/icons/mocha.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    cp "$PROJECT_ROOT/assets/icons/mocha.png" "$APPDIR/$APP_NAME.png"
else
    # Create fallback 256x256 icon
    touch "$APPDIR/$APP_NAME.png"
    touch "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
fi

# Create AppRun entrypoint
cat << 'EOF' > "$APPDIR/AppRun"
#!/usr/bin/env bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/bin/lib:${LD_LIBRARY_PATH}"
cd "${HERE}/usr/bin"
exec "${HERE}/usr/bin/mocha" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Check for appimagetool
APPIMAGETOOL="$PROJECT_ROOT/tool/appimagetool-x86_64.AppImage"
if ! command -v appimagetool &> /dev/null; then
    if [ ! -f "$APPIMAGETOOL" ]; then
        echo "==> Downloading appimagetool..."
        curl -L -o "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
        chmod +x "$APPIMAGETOOL"
    fi
    TOOL="$APPIMAGETOOL"
else
    TOOL="appimagetool"
fi

echo "==> Generating AppImage..."
ARCH=x86_64 "$TOOL" "$APPDIR" "$PROJECT_ROOT/Mocha-x86_64.AppImage"

echo "==> Successfully built: $PROJECT_ROOT/Mocha-x86_64.AppImage"
