# Local, Software — macOS Screensaver

A native macOS screensaver that renders a rippling blue-water surface: a smooth multi-stop gradient distorted by layered sine waves, with procedurally spawned raindrop rings expanding across the puddle and a cursor-driven drag wake that glints where you move the pointer. The visuals live in a single HTML file (WebGL fragment shader + a thin JS driver); a small native bundle (`.saver`) hosts it inside a `WKWebView` so macOS treats it as a real screensaver.

## What's in this repo

```
index.html                        ← markup
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

## Downloadable build (for sharing)

If you want a ready-to-share download (for GitHub Releases, AirDrop, etc.), build a packaged ZIP:

```bash
./macos/build.sh package
```

That creates:

```text
build/downloads/LocalSoftware-macOS.zip
```

The ZIP contains `LocalSoftware.saver` plus an `INSTALL.txt` with end-user install steps. Recipients can install by double-clicking `LocalSoftware.saver` (no Xcode tools required on their machine).

### Automatic GitHub Release downloads

This repo now includes a GitHub Actions workflow at `.github/workflows/release.yml`.

When you push a tag like `v1.0.0`, GitHub Actions will:

1. Build the screensaver.
2. Create `build/downloads/LocalSoftware-macOS.zip`.
3. Attach that ZIP to the GitHub Release for the tag.

Example:

```bash
git tag v1.0.0
git push origin v1.0.0
```

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

To build + install + produce a downloadable ZIP in one run:

```bash
./macos/build.sh install package
```

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

When you change `index.html` or `assets/styles/screensaver.css`, rebuild and reinstall:

```bash
./macos/build.sh install
```

Then toggle to a different screensaver and back to **Local, Software** (or log out and back in) so macOS reloads the bundle.

## Previewing in a browser

You can open `index.html` directly in a web browser to iterate on the design without rebuilding:

```bash
open index.html
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

1. Quit System Settings completely (⌘Q) and reopen it. macOS caches the list.

2. **Clear quarantine** (very common if you downloaded the ZIP with Safari or Chrome). The installed `.saver` may carry `com.apple.quarantine`, which can prevent it from appearing or loading:

   ```bash
   xattr -cr "$HOME/Library/Screen Savers/LocalSoftware.saver"
   ```

   Or run the helper script from the repo:

   ```bash
   ./macos/fix-installed-saver.sh
   ```

3. On **macOS 15+ / 26+**, some users report third-party `.saver` bundles not showing in Settings even when installed correctly; that is an OS-side issue. Try **Screen Saver → Preview** after selecting another saver, or use **Open** on the `.saver` in Finder once more after clearing quarantine.

**The screensaver shows a blank black screen.**
Rebuild once — you may be running an older bundle. Also confirm the `.saver` contains resources:

```bash
ls "$HOME/Library/Screen Savers/LocalSoftware.saver/Contents/Resources"
```

You should see `index.html` and an `assets/` directory.

**`xcrun: error: invalid active developer path`**
Command Line Tools aren't installed. Run `xcode-select --install`.

**Build fails with `ld: library not found`.**
You're likely on a very old macOS. Edit `MIN_MACOS` in `macos/build.sh` to match your system, or upgrade to macOS 11+.

## How it works (short version)

`LocalSoftwareView.swift` is a subclass of `ScreenSaverView` (Apple's official base class for screensavers). On init it:

1. Creates a `WKWebView` sized to the screensaver's bounds.
2. Calls `loadFileURL(_:allowingReadAccessTo:)` on the bundled `index.html`, granting the web view read access to the whole `Resources/` directory so it can resolve the CSS and fonts.

Everything visual is drawn by a single WebGL fragment shader inside `index.html`. One full-screen triangle is rendered per frame; the shader composes:

- a 5-stop blue-water palette (abyss → deep ocean → mid → shallow → foam),
- layered sine waves for the ambient ripple height field,
- a ring-buffer of **raindrop** impacts (random position + birth time) that each emit an expanding shell of ring-shaped waves,
- a ring-buffer of recent **cursor positions** that carve a continuous dragged-groove + wake ring when you move the pointer,
- a fake specular term from screen-space derivatives of the combined height field, with a bluer tint under the drag.

Because all animation is driven on the GPU by a `requestAnimationFrame` loop inside the web view, `animateOneFrame()` in Swift stays a no-op. `Info.plist` declares `CFBundlePackageType=BNDL` and `NSPrincipalClass=LocalSoftwareView`, which is all macOS's screensaver loader looks for.

> Note: cursor interaction is only visible when the HTML runs in a context that accepts mouse input (e.g. opened directly in a browser, or the System Settings preview). When the saver is actually active as the system screensaver, macOS dismisses the saver as soon as the mouse moves, so the drag effect is primarily a design-time nicety.

## A note on the fonts

The ABC Diatype Mono `-Trial` weights are still bundled for evaluation only — the `@font-face` rules live in `assets/styles/screensaver.css` and the original `.title` markup is commented out in `index.html`. Uncomment it if you want text on top of the water. Swap in a licensed copy before distributing this beyond your own machine.
