#!/usr/bin/env bash
# Build a macOS .saver bundle: LocalSoftware.saver
#
# Usage:
#   ./macos/build.sh                  # build Release .saver into ./build
#   ./macos/build.sh install          # build, then copy into ~/Library/Screen Savers
#   ./macos/build.sh package          # build + create downloadable zip in ./build/downloads
#   ./macos/build.sh install package  # build, install locally, and create zip

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

NAME="LocalSoftware"
BUNDLE="${NAME}.saver"
BUILD_DIR="${ROOT_DIR}/build"
OUT_BUNDLE="${BUILD_DIR}/${BUNDLE}"
OBJ_DIR="${BUILD_DIR}/obj"
DOWNLOADS_DIR="${BUILD_DIR}/downloads"
PACKAGE_PREFIX="${NAME}-macOS"

SWIFT_SRC="${SCRIPT_DIR}/LocalSoftwareView.swift"
INFO_PLIST="${SCRIPT_DIR}/Info.plist"

HTML_SRC="${ROOT_DIR}/index.html"
ASSETS_SRC="${ROOT_DIR}/assets"

MIN_MACOS="11.0"

DO_INSTALL=0
DO_PACKAGE=0
for arg in "$@"; do
    case "${arg}" in
        install)
            DO_INSTALL=1
            ;;
        package)
            DO_PACKAGE=1
            ;;
        *)
            echo "Unknown argument: ${arg}"
            echo "Usage: ./macos/build.sh [install] [package]"
            exit 1
            ;;
    esac
done

echo "→ Cleaning ${OUT_BUNDLE}"
rm -rf "${OUT_BUNDLE}" "${OBJ_DIR}"
mkdir -p "${OUT_BUNDLE}/Contents/MacOS"
mkdir -p "${OUT_BUNDLE}/Contents/Resources"
mkdir -p "${OBJ_DIR}/arm64" "${OBJ_DIR}/x86_64"

compile_arch() {
    local arch="$1"
    echo "→ Compiling ${arch}"
    xcrun swiftc \
        -module-name "${NAME}" \
        -emit-library \
        -Xlinker -bundle \
        -target "${arch}-apple-macos${MIN_MACOS}" \
        -O \
        -framework AppKit \
        -framework ScreenSaver \
        -framework WebKit \
        -o "${OBJ_DIR}/${arch}/${NAME}" \
        "${SWIFT_SRC}"
}

compile_arch arm64
compile_arch x86_64

echo "→ Creating universal binary"
xcrun lipo -create \
    "${OBJ_DIR}/arm64/${NAME}" \
    "${OBJ_DIR}/x86_64/${NAME}" \
    -output "${OUT_BUNDLE}/Contents/MacOS/${NAME}"

echo "→ Copying Info.plist"
cp "${INFO_PLIST}" "${OUT_BUNDLE}/Contents/Info.plist"

echo "→ Copying resources"
cp "${HTML_SRC}" "${OUT_BUNDLE}/Contents/Resources/index.html"
mkdir -p "${OUT_BUNDLE}/Contents/Resources/assets"
cp -R "${ASSETS_SRC}/fonts" "${OUT_BUNDLE}/Contents/Resources/assets/"
cp -R "${ASSETS_SRC}/styles" "${OUT_BUNDLE}/Contents/Resources/assets/"

# Drop the raw .zip from the bundled Resources to keep it lean.
rm -f "${OUT_BUNDLE}/Contents/Resources/assets/fonts/ABC Diatype Mono.zip"

# Clear Finder metadata/resource forks so codesign is deterministic.
xattr -cr "${OUT_BUNDLE}"

echo "→ Ad-hoc code signing"
codesign --force --deep --sign - "${OUT_BUNDLE}"

echo "✓ Built: ${OUT_BUNDLE}"

if [[ "${DO_INSTALL}" -eq 1 ]]; then
    DEST="${HOME}/Library/Screen Savers"
    mkdir -p "${DEST}"
    rm -rf "${DEST}/${BUNDLE}"
    cp -R "${OUT_BUNDLE}" "${DEST}/"
    # Downloads / Finder copies can inherit com.apple.quarantine; strip so the
    # Screen Saver engine can load the bundle (same as macos/fix-installed-saver.sh).
    xattr -cr "${DEST}/${BUNDLE}"
    echo "✓ Installed to: ${DEST}/${BUNDLE}"
    echo "  Open System Settings → Screen Saver and pick 'Local, Software'."
fi

if [[ "${DO_PACKAGE}" -eq 1 ]]; then
    PKG_ROOT="${DOWNLOADS_DIR}/${PACKAGE_PREFIX}"
    PKG_ZIP="${DOWNLOADS_DIR}/${PACKAGE_PREFIX}.zip"
    INSTALL_NOTES="${PKG_ROOT}/INSTALL.txt"

    echo "→ Creating downloadable package"
    rm -rf "${PKG_ROOT}" "${PKG_ZIP}"
    mkdir -p "${PKG_ROOT}"
    cp -R "${OUT_BUNDLE}" "${PKG_ROOT}/"

    cat > "${INSTALL_NOTES}" <<'EOF'
Local, Software macOS Screensaver
=================================

Install (no build tools needed):

1. Double-click LocalSoftware.saver in Finder (or drag it to ~/Library/Screen Savers).
2. Confirm install when macOS prompts.

REQUIRED if it does not appear in the Screen Saver list (browser downloads add
"quarantine" flags that block loading). In Terminal, run:

  xattr -cr "$HOME/Library/Screen Savers/LocalSoftware.saver"

If you also copied to the system folder:

  sudo xattr -cr "/Library/Screen Savers/LocalSoftware.saver"

Then quit System Settings completely (⌘Q), reopen, and look for "Local, Software".

3. Open System Settings -> Screen Saver and select "Local, Software".

If macOS blocks it (first run, expected):

1. Open System Settings -> Privacy & Security.
2. Click "Open Anyway" for LocalSoftware.
3. Confirm with Touch ID / password.

Note: On recent macOS versions, some third-party .saver modules are flaky in
System Settings. If nothing helps, use Preview on the thumbnail or open
index.html in a browser (same visuals) as a fallback.
EOF

    (
        cd "${DOWNLOADS_DIR}"
        /usr/bin/zip -qry "${PKG_ZIP}" "${PACKAGE_PREFIX}"
    )
    echo "✓ Download package: ${PKG_ZIP}"
fi
