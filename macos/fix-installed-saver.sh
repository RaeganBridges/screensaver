#!/usr/bin/env bash
# Remove quarantine and extended attributes from installed LocalSoftware.saver.
# Run this after copying from a browser download or ZIP — Gatekeeper often tags
# the bundle and macOS may not list or load the screensaver until cleared.
#
# Usage: ./macos/fix-installed-saver.sh

set -euo pipefail

BUNDLE="LocalSoftware.saver"
USER_SAVER="${HOME}/Library/Screen Savers/${BUNDLE}"
SYSTEM_SAVER="/Library/Screen Savers/${BUNDLE}"

fix_one() {
    local path="$1"
    if [[ -e "${path}" ]]; then
        echo "→ Clearing attributes: ${path}"
        xattr -cr "${path}"
    else
        echo "(skip, not found: ${path})"
    fi
}

fix_one "${USER_SAVER}"
fix_one "${SYSTEM_SAVER}"
echo "✓ Done. Quit System Settings (⌘Q), reopen it, then check Screen Saver for \"Local, Software\"."
