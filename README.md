# make-a-dmg

Turn any macOS app into a polished, drag-to-install `.dmg`. No install, no dependencies.

## Use it

Open **Terminal** (in any folder) and paste this one line:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg)
```

That is the whole thing. It **opens a picker so you can choose any app**, or, if the folder you ran it in happens to have a `.app`, it just uses that. Then it builds a ready-to-share `.dmg`. Nothing is installed, and nothing is left on your Mac.

Want it to ask you about each option (background, size, icon, and so on)? Add `-i`:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg) -i
```

### Prefer to keep a copy?

If you will use it often, download it once and run it by name:

```sh
curl -fsSLO https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg
chmod +x make-a-dmg
./make-a-dmg
```

From here on the examples use `make-a-dmg` for short. If you did not keep a copy, just replace it with the `bash <(curl ...)` line above, everything after it works the same.

---

## What you get

- The app on the left, an **Applications** shortcut on the right, drag to install.
- The app's **own icon** set as the disk icon, automatically.
- A clean, compressed `.dmg` named `AppName-version.dmg`.

---

## The guided wizard

Not sure what to set? Run with `-i` and it walks you through every option. Each prompt shows the current value in brackets; press Enter to keep it.

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

Type `p` at the background prompt to choose an image with a picker.

---

## Backgrounds and fit modes

Give it a background image and it places it in the window for you. **Your window size is always respected**, the image is fitted into it. Choose how with `--fit`:

| Mode | What it does | Distorts? | Crops? | Use when |
|---|---|---|---|---|
| **crop** (default) | Covers the window, trims the overflow | no | edges | You want the window filled edge to edge |
| **contain** | Fits inside, leaves margins | no | no | You must see the whole image |
| **stretch** | Squishes to fill exactly | yes | no | Almost never |
| **window** | Sizes the **window** to the image instead | no | no | You want the window to match the image |

```sh
make-a-dmg MyApp.app --background art/bg.png            # crop to fill (default)
make-a-dmg MyApp.app --background art/bg.png --fit contain
make-a-dmg MyApp.app --background art/bg.png --fit window
```

Design your background with the arrow baked in: with the default crop the app icon and the Applications shortcut land in the left and right thirds, vertically centered, so they line up with an arrow drawn in your art. Retina (2x) images just work.

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

A name typed without `.dmg` gets it added, and a missing output folder is created.

---

## Examples

```sh
# build from the app in the current folder
make-a-dmg

# your background art (window stays 660x500, image cropped to fill)
make-a-dmg MyApp.app --background art/bg.png

# match the window to a designed background image
make-a-dmg MyApp.app --background art/window-1024.png --fit window

# fixed window and exact icon placement
make-a-dmg MyApp.app --window-size 700x520 --app-pos 175,250 --drop-pos 525,250

# build into a dist folder with a checksum, for releases
make-a-dmg ~/build/MyApp.app -o dist/ --sha256

# override the icon and the version in the name
make-a-dmg MyApp.app --icon brand/icon.png --version 2.1.0

# fully unattended (for CI or scripts)
make-a-dmg MyApp.app -y --sha256 -o dist/MyApp.dmg
```

---

## How it works

Everything is done with tools that ship with macOS: `hdiutil` builds and compresses the disk image, `osascript` (Finder) lays out the window, and `sips` + `iconutil` prepare the icon and fit the background. An `/Applications` symlink is the drag target. The image work happens before the disk image is assembled, and the layout step verifies Finder actually saved the window and retries if it did not, so you get a properly styled window every time.

---

## Troubleshooting

**The first run asks to control Finder.** Styling the window uses Finder, so macOS shows "Terminal wants to control Finder" once. Allow it (System Settings > Privacy & Security > Automation). If you decline, the dmg still builds, just without the laid-out window.

**My app has no custom disk icon.** Apps that keep their icon only in an asset catalog have no standalone `.icns` to read. Pass one with `--icon your.png` (a PNG is converted for you).

**Gatekeeper warns when opening the app.** This tool packages your app as-is. An unsigned, un-notarized app still warns on first open; that is separate from this tool.

---

## Requirements

macOS only. Uses `hdiutil`, `osascript`, `sips`, `iconutil`, all built in. No Homebrew, no third-party tools.

---

## Testing

A self-contained smoke test builds throwaway dmgs (from a dummy app it creates itself) and checks the deterministic behavior: valid image, contents, naming, checksum, and background fit.

```sh
./test.sh
```

It prints a `passed / failed` summary and exits non-zero on failure. It does not test the Finder window styling, which needs GUI automation.

---

## License

MIT. See [LICENSE](LICENSE).

Made by [KodeElite](https://kodeelite.com).
