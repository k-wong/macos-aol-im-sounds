#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="macOS Soundboard"
PRODUCT_NAME="MacOSSoundboardUtility"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/release"
DIST_DIR="$ROOT_DIR/dist"
CACHE_DIR="$ROOT_DIR/.cache"
WORK_DIR="$DIST_DIR/.package-work"
APP_DIR="$WORK_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$WORK_DIR/AppIcon.iconset"
ICON_FILE="$RESOURCES_DIR/AppIcon.icns"
ZIP_PATH="$DIST_DIR/macos-soundboard-unsigned.zip"
SVG_ICON="$ROOT_DIR/app-icon-on.svg"
RESOURCE_BUNDLE="$BUILD_DIR/${PRODUCT_NAME}_${PRODUCT_NAME}.bundle"
EXECUTABLE_SOURCE="$BUILD_DIR/$PRODUCT_NAME"

check_required_tools() {
    local developer_dir
    developer_dir="$(xcode-select -p 2>/dev/null || true)"

    if [[ -z "$developer_dir" ]]; then
        cat <<'EOF' >&2
Apple developer tools are not configured.
Install Command Line Tools or Xcode, then run:

  xcode-select --install
EOF
        exit 1
    fi

    for tool_name in swift iconutil ditto; do
        if ! command -v "$tool_name" >/dev/null 2>&1; then
            printf 'Required tool not found: %s\n' "$tool_name" >&2
            printf 'Install Command Line Tools with `xcode-select --install`, or install Xcode.\n' >&2
            exit 1
        fi
    done
}

run_swift_build() {
    local developer_dir
    developer_dir="$(xcode-select -p 2>/dev/null || true)"

    if ! swift build -c release --package-path "$ROOT_DIR"; then
        cat <<EOF >&2

Swift build failed.

See the compiler output above for the specific error.

If you are using Command Line Tools only and the error looks toolchain-related, reinstall or update them:
  xcode-select --install

If you have full Xcode installed and the error looks SDK/toolchain-related, switching to it may also fix the issue:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
EOF
        exit 1
    fi
}

mkdir -p "$CACHE_DIR/clang/ModuleCache" "$CACHE_DIR/swiftpm"
export CLANG_MODULE_CACHE_PATH="$CACHE_DIR/clang/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$CACHE_DIR/swiftpm"

check_required_tools

rm -rf "$WORK_DIR" "$ZIP_PATH"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

run_swift_build

if [[ ! -f "$EXECUTABLE_SOURCE" ]]; then
    echo "missing executable at $EXECUTABLE_SOURCE" >&2
    exit 1
fi

if [[ ! -d "$RESOURCE_BUNDLE" ]]; then
    echo "missing resource bundle at $RESOURCE_BUNDLE" >&2
    exit 1
fi

cp "$EXECUTABLE_SOURCE" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"
cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"

swift "$ROOT_DIR/scripts/render_app_icon.swift" "$SVG_ICON" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>macOS Soundboard</string>
    <key>CFBundleExecutable</key>
    <string>macOS Soundboard</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.macossoundboard.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>macOS Soundboard</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

touch "$CONTENTS_DIR/PkgInfo"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

rm -rf "$WORK_DIR"

echo "Created unsigned zip at $ZIP_PATH"
