# Local, Software — macOS Screensaver

A native macOS screensaver that shows an animated gradient with **Local, Software** set in ABC Diatype Mono across the top. The visuals live in an HTML/CSS file; a small native bundle (`.saver`) hosts it inside a `WKWebView` so macOS treats it as a real screensaver.

## What's in this repo

```
screensaver.html                        ← markup
assets/
  styles/screensaver.css                ← all styles + @font-face rules
  fonts/ABC Diatype Mono/*.woff2        ← bundled fonts
macos/
  LocalSoftwareView.swift               ← native ScreenSaverView + WKWebView
  Info.plist                            ← .saver bundle metadata
  build.sh                              ← builds and (optionally) installs
build/LocalSoftware.saver               ← created by build.sh (git-ignored)
```

## Requirements

- macOS 11 Big Sur or newer
- Xcode Command Line Tools — if you don't have them, run:

```bash
xcode-select --install
```

You do **not** need the full Xcode app. The build uses `swiftc`, `lipo`, and `codesign`, all of which ship with the Command Line Tools.

---

## Install (three steps)

### 1. Clone and build

From a terminal:

```bash
git clone <this-repo-url>
cd screensaver
./macos/build.sh install
```

The `install` argument tells the script to:

1. Compile a universal (`arm64 + x86_64`) Swift binary.
2. Assemble `build/LocalSoftware.saver` with the HTML, CSS, and fonts inside.
3. Ad-hoc code-sign the bundle.
4. Copy it to `~/Library/Screen Savers/LocalSoftware.saver`.

If you just want to build without installing, run `./macos/build.sh` (no argument). You can then double-click `build/LocalSoftware.saver` in Finder to install it the GUI way.

### 2. Approve it in Privacy & Security (first time only)

Because the bundle is ad-hoc signed (not notarized by Apple), macOS will block it the first time the screensaver engine tries to load it. This is expected.

1. Open **System Settings → Privacy & Security**.
2. Scroll to the bottom.
3. You'll see a message like: *"LocalSoftware was blocked from use because it is not from an identified developer."*
4. Click **Open Anyway** and confirm with Touch ID / your password.

If the dialog doesn't appear, an alternative is: open Finder, navigate to `~/Library/Screen Savers/`, right-click `LocalSoftware.saver`, choose **Open**, and confirm the warning. You only need to do this once.

> Tip: in Finder, the fastest way to reach `~/Library` is **Go → Go to Folder…** (⇧⌘G) and paste `~/Library/Screen Savers`.

### 3. Select it in System Settings

1. Open **System Settings → Screen Saver**.
2. Pick **Local, Software** from the list.
3. Set your preferred **Show screen saver after…** delay under **Lock Screen** in System Settings.

To preview immediately: hover the thumbnail in the Screen Saver pane and click **Preview**, or trigger your Hot Corner / Lock Screen.

---

## Updating

When you change `screensaver.html` or `assets/styles/screensaver.css`, rebuild and reinstall:

```bash
./macos/build.sh install
```

Then toggle to a different screensaver and back to **Local, Software** (or log out and back in) so macOS reloads the bundle.

## Previewing in a browser

You can open `screensaver.html` directly in a web browser to iterate on the design without rebuilding:

```bash
open screensaver.html
```

Press **F** (or use the browser's full-screen) for a proper fullscreen preview. The HTML and the screensaver use the exact same file, so anything that looks right in the browser will look right in the screensaver.

## Uninstall

```bash
rm -rf ~/Library/Screen\ Savers/LocalSoftware.saver
```

Then restart **System Settings** if it's open.

---

## Troubleshooting

**"LocalSoftware can't be opened because Apple cannot check it for malicious software."**
Expected on first launch. Follow step 2 above (Privacy & Security → Open Anyway).

**The screensaver list doesn't show "Local, Software" after install.**
Quit System Settings completely (⌘Q) and reopen it. macOS caches the list.

**The screensaver shows a blank black screen.**
Rebuild once — you may be running an older bundle. Also confirm the `.saver` contains resources:

```bash
ls "$HOME/Library/Screen Savers/LocalSoftware.saver/Contents/Resources"
```

You should see `screensaver.html` and an `assets/` directory.

**`xcrun: error: invalid active developer path`**
Command Line Tools aren't installed. Run `xcode-select --install`.

**Build fails with `ld: library not found`.**
You're likely on a very old macOS. Edit `MIN_MACOS` in `macos/build.sh` to match your system, or upgrade to macOS 11+.

## How it works (short version)

`LocalSoftwareView.swift` is a subclass of `ScreenSaverView` (Apple's official base class for screensavers). On init it:

1. Creates a `WKWebView` sized to the screensaver's bounds.
2. Calls `loadFileURL(_:allowingReadAccessTo:)` on the bundled `screensaver.html`, granting the web view read access to the whole `Resources/` directory so it can resolve the CSS and fonts.

The gradient animation is pure CSS keyframes, so `animateOneFrame()` is a no-op — the browser engine handles timing for us. `Info.plist` declares `CFBundlePackageType=BNDL` and `NSPrincipalClass=LocalSoftwareView`, which is all macOS's screensaver loader looks for.

## A note on the fonts

The bundled `-Trial` weights of ABC Diatype Mono are for evaluation only. Swap in a licensed copy before distributing this beyond your own machine.
