# make-a-dmg

Turn a macOS `.app` into a polished, drag-to-install `.dmg`, with **zero dependencies.**

No Homebrew, no `create-dmg`, nothing to install. It uses only tools that already ship with every Mac (`hdiutil`, `osascript`, `sips`, `iconutil`), so it also runs straight from the web in a single line.

```sh
./make-a-dmg
```

That one command finds the `.app` in the current folder (or opens a picker), pulls the icon from the app itself, lays out a nice drag-to-Applications window, and writes `AppName-version.dmg` right next to it.

---

## Contents

- [Install](#install)
- [Quick start](#quick-start)
- [The guided wizard](#the-guided-wizard)
- [Backgrounds and fit modes](#backgrounds-and-fit-modes)
- [Options](#options)
- [Examples](#examples)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Testing](#testing)
- [License](#license)

---

## Install

Download the script and make it executable:

```sh
curl -fsSLO https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg
chmod +x make-a-dmg
```

Or run it from the web with nothing saved to disk:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg) /path/to/YourApp.app
```

---

## Quick start

Drop the script next to your built `.app` and run it:

```sh
./make-a-dmg
```

With no arguments it uses the `.app` in the current folder. If several are present it asks which one; if none are present it opens a native file picker so you can point at one anywhere.

Point it at an app explicitly:

```sh
./make-a-dmg ~/build/MyApp.app
```

The result is a compressed `.dmg` with your app on the left, an Applications shortcut on the right, and the app's own icon set as the disk icon.

---

## The guided wizard

Not sure which options you want? Run the wizard and it walks you through every setting. Each prompt shows the current value in brackets, and pressing Enter keeps it.

```sh
./make-a-dmg -i
```

```
▸ Setup: Enter keeps each [default]
   Background image (path, or p to pick) [none] ›
   Fit background: crop / contain / stretch / window [crop] ›
   Window size WxH [660x500] ›
   Icon size [120] ›
   App icon position X,Y [165,190] ›
   Applications position X,Y [495,190] ›
   Volume name [MyApp] ›
   Custom icon (path, or none) [app default] ›
   Output [MyApp-1.0.0.dmg] ›
   Also write a .sha256 checksum? (y/n) [no] ›
   Reveal in Finder when done? (y/n) [yes] ›
```

Type `p` at the background prompt to pick an image with a file picker. Anything you pass on the command line becomes the pre-filled default in the wizard.

---

## Backgrounds and fit modes

Give the tool a background image and it places it in the window for you. **Your window size is always respected**, the image is fitted into it. Choose how with `--fit`:

| Mode | What it does | Distortion | Crop | Use when |
|---|---|---|---|---|
| **crop** (default) | Scales the image to cover the window, trims the overflow | none | edges | You want the window filled edge to edge |
| **contain** | Scales the image to fit inside, leaves margins | none | none | You must see the whole image |
| **stretch** | Squishes the image to fill exactly | yes | none | Almost never |
| **window** | Sizes the **window** to the image instead | none | none | You want the window to match the image |

```sh
./make-a-dmg MyApp.app --background art/bg.png            # crop to fill (default)
./make-a-dmg MyApp.app --background art/bg.png --fit contain
./make-a-dmg MyApp.app --background art/bg.png --fit window
```

The build plan tells you exactly what happened, for example `1024x1024 cropped to fill 660x500` or `exact fit`.

Notes:
- **Design your background with the arrow baked in.** With the default crop, the app icon and Applications shortcut land in the left and right thirds, vertically centered, so they line up with an arrow drawn in your art.
- **Retina images just work.** A 2x screenshot no longer shrinks into a corner; backgrounds are normalized so 1 pixel equals 1 point.
- Add a `bg@2x.png` sibling next to your background for crisp Retina rendering.

---

## Options

```
<path.app>           app to package (default: the .app in this folder, or a picker)
-i, --interactive    ask through every option, Enter keeps each default (also --wizard)
--background FILE     window background image (png/jpg); a @2x sibling is used if present
--fit MODE           how the background fills the window (default crop):
                       crop     cover the window and trim overflow (keeps aspect, no gaps)
                       contain  fit inside with margins (keeps aspect, no crop)
                       stretch  distort to fill exactly
                       window   size the window to the image instead
--icon FILE          volume/dmg icon (.icns or .png); default: the app's own icon
--no-icon            build without a custom icon
--volname NAME       volume/window name (default: the app name)
-o, --output PATH    output file or directory (default: <App>-<version>.dmg here)
--window-size WxH    Finder window size (default: 660x500)
--icon-size N        icon size in the window (default: 120)
--app-pos X,Y        position of the app icon (default: auto-centered)
--drop-pos X,Y       position of the Applications link (default: auto-centered)
--version VER        override the version used in the output name
--sha256             also write <dmg>.sha256 next to the dmg
--no-open            do not reveal the dmg in Finder when done
-y, --yes            non-interactive: no prompts
-h, --help           show help
```

If you type an output name without `.dmg`, it is added for you, and a missing output folder is created.

---

## Examples

```sh
# simplest: build from the app in this folder
./make-a-dmg

# your background art with a baked-in arrow (window stays 660x500, image cropped to fill)
./make-a-dmg MyApp.app --background art/bg.png

# match the window to a designed background image
./make-a-dmg MyApp.app --background art/window-1024.png --fit window

# fixed window and exact icon placement
./make-a-dmg MyApp.app --window-size 700x520 --app-pos 175,250 --drop-pos 525,250

# build elsewhere, into a dist folder, with a checksum for releases
./make-a-dmg ~/build/MyApp.app -o dist/ --sha256

# override the icon and the version shown in the file name
./make-a-dmg MyApp.app --icon brand/icon.png --version 2.1.0

# fully unattended (for CI or scripts)
./make-a-dmg MyApp.app -y --sha256 -o dist/MyApp.dmg
```

---

## How it works

Everything is done with built-in macOS tools:

- **`hdiutil`** builds and compresses the disk image.
- **`osascript`** (Finder) lays out the window: size, icon positions, and background.
- **`sips` + `iconutil`** prepare the icon and fit the background.
- An `/Applications` symlink is the drag target.

All image work (fitting the background, building the icon) happens first, before the disk image is assembled, so the build step never has to manipulate images. The layout step verifies that Finder actually saved the window (the `.DS_Store`) and retries if it did not, so you get a properly styled window every time, not an occasional plain one.

---

## Troubleshooting

**The first run asks to control Finder.** Styling the window uses Finder, so the first time macOS shows "Terminal wants to control Finder." Allow it once (System Settings > Privacy & Security > Automation). You only do this once. If you decline, the dmg still builds, just without the laid-out window.

**My app has no custom disk icon.** Apps that keep their icon only in an asset catalog have no standalone `.icns` for the tool to read. Pass your icon directly with `--icon your.png` (a PNG is converted to a crisp multi-size icon automatically).

**Gatekeeper warns when opening the app from the dmg.** This tool packages your app as-is. If the app is not signed and notarized, macOS still warns on first open. Signing and notarization are outside the scope of this tool.

---

## Requirements

- macOS (uses `hdiutil`, `osascript`, `sips`, `iconutil`, all built in)
- A built `.app`

No Homebrew, no third-party tools.

---

## Testing

A self-contained smoke test builds throwaway dmgs (from a dummy app it creates itself, no external app needed) and checks the deterministic behavior: valid image, contents, output naming, checksum, and background fit.

```sh
./test.sh
```

It prints a `passed / failed` summary and exits non-zero on any failure. It deliberately does not test the Finder window styling, which needs GUI automation and would false-fail on headless CI.

---

## License

MIT. See [LICENSE](LICENSE).

Made by [KodeElite](https://kodeelite.com).
