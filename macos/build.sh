#!/usr/bin/env bash
# Build a macOS .saver bundle: LocalSoftware.saver
#
# Usage:
#   ./macos/build.sh            # build Release .saver into ./build
#   ./macos/build.sh install    # build, then copy into ~/Library/Screen Savers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

NAME="LocalSoftware"
BUNDLE="${NAME}.saver"
BUILD_DIR="${ROOT_DIR}/build"
OUT_BUNDLE="${BUILD_DIR}/${BUNDLE}"
OBJ_DIR="${BUILD_DIR}/obj"

SWIFT_SRC="${SCRIPT_DIR}/LocalSoftwareView.swift"
INFO_PLIST="${SCRIPT_DIR}/Info.plist"

HTML_SRC="${ROOT_DIR}/screensaver.html"
ASSETS_SRC="${ROOT_DIR}/assets"

MIN_MACOS="11.0"

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
cp "${HTML_SRC}" "${OUT_BUNDLE}/Contents/Resources/screensaver.html"
mkdir -p "${OUT_BUNDLE}/Contents/Resources/assets"
cp -R "${ASSETS_SRC}/fonts" "${OUT_BUNDLE}/Contents/Resources/assets/"
cp -R "${ASSETS_SRC}/styles" "${OUT_BUNDLE}/Contents/Resources/assets/"

# Drop the raw .zip from the bundled Resources to keep it lean.
rm -f "${OUT_BUNDLE}/Contents/Resources/assets/fonts/ABC Diatype Mono.zip"

echo "→ Ad-hoc code signing"
codesign --force --deep --sign - "${OUT_BUNDLE}"

echo "✓ Built: ${OUT_BUNDLE}"

if [[ "${1:-}" == "install" ]]; then
    DEST="${HOME}/Library/Screen Savers"
    mkdir -p "${DEST}"
    rm -rf "${DEST}/${BUNDLE}"
    cp -R "${OUT_BUNDLE}" "${DEST}/"
    echo "✓ Installed to: ${DEST}/${BUNDLE}"
    echo "  Open System Settings → Screen Saver and pick 'Local, Software'."
fi
