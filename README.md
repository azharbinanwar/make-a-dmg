# make-a-dmg

Turn any macOS app into a polished, drag-to-install `.dmg`. No install, no dependencies.

[![test](https://github.com/azharbinanwar/make-a-dmg/actions/workflows/test.yml/badge.svg)](https://github.com/azharbinanwar/make-a-dmg/actions/workflows/test.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![dependencies: none](https://img.shields.io/badge/dependencies-none-brightgreen.svg)

## Pick one

|                              | 🌐 Run it online                       | 💾 Install it                               |
| ---------------------------- | -------------------------------------- | ------------------------------------------- |
| **Command**                  | `bash <(curl -fsSL kodeelite.com/dmg)` | `brew install azharbinanwar/tap/make-a-dmg` |
| **Puts a file on your Mac?** | No, nothing at all                     | Yes, one script in your PATH                |
| **Next time you use it**     | Paste the same line again              | Just type `make-a-dmg`                      |
| **Version you get**          | Always the current release             | `brew upgrade` when you want a newer one    |
| **Best for**                 | Packaging an app once                  | Using it regularly                          |

Both do exactly the same thing. Pick whichever suits you.

---

## 🌐 Run it online

Nothing is installed and nothing is left behind. Open **Terminal** in any folder and paste:

```sh
bash <(curl -fsSL kodeelite.com/dmg)
```

That is the whole thing. It **opens a picker so you can choose any app**, or, if the folder you ran it in happens to have a `.app`, it just uses that. Then it builds a ready-to-share `.dmg`.

Want it to ask you about each option (background, size, icon, and so on)? Add `-i`:

```sh
bash <(curl -fsSL kodeelite.com/dmg) -i
```

---

## 💾 Install it

Puts one script in your PATH, so afterwards you just type `make-a-dmg` from any folder.

```sh
brew install azharbinanwar/tap/make-a-dmg
```

No Homebrew? One line does the same:

```sh
curl -fsSL kodeelite.com/dmg -o /usr/local/bin/make-a-dmg && chmod +x /usr/local/bin/make-a-dmg
```

Then, from anywhere:

```sh
make-a-dmg              # build from the app in this folder
make-a-dmg -i           # walk through every option
make-a-dmg MyApp.app    # or name the app
```

Check which version you have:

```sh
make-a-dmg --version      # make-a-dmg 1.0.0
```

To remove it later: `brew uninstall make-a-dmg`, or `rm /usr/local/bin/make-a-dmg` if you installed it by hand.

<details>
<summary>Straight from GitHub, or pinned to a version</summary>

`kodeelite.com/dmg` is a redirect to the current release on GitHub. To skip it, or to pin an exact version:

```sh
# latest on main
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg)

# a specific release
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/v1.0.0/make-a-dmg)
```

And to read it before running it, which is a fair thing to do with any script from the internet:

```sh
curl -fsSL kodeelite.com/dmg | less
```

</details>

---

## How to read the rest of this page

Everything below is written as `make-a-dmg …`. That is a stand-in for whichever way you are using it — both accept exactly the same options, in the same order:

| You are using          | Write this                                     |
| ---------------------- | ---------------------------------------------- |
| 🌐 **Run it online**   | `bash <(curl -fsSL kodeelite.com/dmg) …`       |
| 💾 **Installed**       | `make-a-dmg …`                                 |

So an example written as:

```sh
make-a-dmg MyApp.app --background art/bg.png
```

is either of these, depending on which you picked:

```sh
bash <(curl -fsSL kodeelite.com/dmg) MyApp.app --background art/bg.png   # online
make-a-dmg MyApp.app --background art/bg.png                             # installed
```

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
   Window size WxH [660x500] ›
   Background  · ↑↓ move · Enter picks
 ❯ no background   the plain Finder window
   pick an image   opens a file picker
   a solid color   a hex color like 1e1e1e, no image needed
   type a path     if you already know where it is
   Fit the background into 660x500  · ↑↓ move · Enter picks
 ❯ crop     cover it, trim the overflow
   contain  fit inside, leave margins
   stretch  distort to fill exactly
   window   resize the window to the image instead
   Icon size [120] ›
   App icon position X,Y [165,190] ›
   Applications position X,Y [495,190] ›
   Volume name [MyApp] ›
   Custom icon (path, or none) [app default] ›
   Signing identity  · ↑↓ move · Enter picks · q skips
     Developer ID Application: You (TEAM123)
   ❯ don't sign
   Output [MyApp-1.0.0.dmg] ›
   Also write a .sha256 checksum? (y/n) [no] ›
   Reveal in Finder when done? (y/n) [yes] ›
```

The background prompt is a menu: no background, a file picker, a hex color, or type a path. Whatever the picker returns is echoed back so you can see which file you actually chose.

The window size comes first, because "crop into what?" means nothing until the window is decided. Then the image and how it fits are asked together, with nothing in between. Choosing **window** at the fit prompt is the later, more specific answer, so it overrides the size and tells you the new one:

```
   ✓ window resized to the image: 1320x1000
```

The fit prompt is skipped if you already passed `--fit`, and never appears without a background. Sizes and positions are checked as you type, so a typo re-asks instead of failing later.

---

## Backgrounds and fit modes

### A solid color, no image needed

Pass a hex color instead of a path and the background is generated for you, exactly window-sized. The `#` is optional — leave it off and you do not have to quote it, since an unquoted `#` starts a shell comment and would swallow the rest of your command.

```sh
make-a-dmg MyApp.app --background 1e1e1e
make-a-dmg MyApp.app --background '#1e1e1e'    # same thing
```

There is nothing to fit, so `--fit` is ignored, and a flat color needs no retina variant.

### Fitting an image

Give it a background image and it places it in the window for you. **Your window size is always respected**, the image is fitted into it. Choose how with `--fit`:

| Mode               | What it does                              | Distorts? | Crops? | Use when                                |
| ------------------ | ----------------------------------------- | --------- | ------ | --------------------------------------- |
| **crop** (default) | Covers the window, trims the overflow     | no        | edges  | You want the window filled edge to edge |
| **contain**        | Fits inside, leaves margins               | no        | no     | You must see the whole image            |
| **stretch**        | Squishes to fill exactly                  | yes       | no     | Almost never                            |
| **window**         | Sizes the **window** to the image instead | no        | no     | You want the window to match the image  |

```sh
make-a-dmg MyApp.app --background art/bg.png            # crop to fill (default)
make-a-dmg MyApp.app --background art/bg.png --fit contain
make-a-dmg MyApp.app --background art/bg.png --fit window
```

`--fit window` sizes the window from the image, so it cannot be combined with `--window-size` — that combination is rejected rather than silently letting one win.

Design your background with the arrow baked in: with the default crop the app icon and the Applications shortcut land in the left and right thirds, vertically centered, so they line up with an arrow drawn in your art.

### Leave room at the bottom

A dmg carries no code — the window layout is a snapshot that Finder replays, so nothing can adapt to the machine opening it. Toolbar, status bar and path bar are switched off for you and that travels inside the dmg, but the **tab bar** is a global Finder preference on each viewer's Mac and cannot be reached from a disk image. Someone with it on loses about 36 points off the bottom.

So keep the arrow, any text, and the icons in the middle band, and treat the bottom ~60 pixels as background colour only. Then an unusual Finder costs a viewer some empty space instead of your instructions. If you position icons low enough to be at risk, the build says so:

```
! Icons sit low in the window; Macs with the Finder tab bar on would cut them off.
  keep both Y values at or under 324 to be safe everywhere
```

### Retina

Finder sizes a background by pixels ÷ DPI, so an image at double the pixels tagged 144 dpi covers the same window and stays sharp on a retina screen. That happens automatically when either is true:

- a `@2x` sibling sits next to your image (`bg.png` + `bg@2x.png`), or
- the image you pass is already at least twice the window in both directions.

You will see `retina background (…, 2x at 144 dpi)` in the build output when it kicks in.

---

## Options

```
<path.app>           app to package (default: the .app in this folder, or a picker)
-i, --interactive    ask through every option, Enter keeps each default (also --wizard)
--background WHAT    an image (png/jpg; a @2x sibling is used if present), or a
                     hex color like 1e1e1e / '#1e1e1e' for a plain background
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
--app-version VER    override the app version used in the output name
-v, --version        print the version of make-a-dmg itself (also -V)
--sign [IDENTITY]    sign the dmg; picks or lists your identities (never signs unless asked)
--sha256             also write <dmg>.sha256 next to the dmg
--no-open            do not reveal the dmg in Finder when done
--no-window          skip the Finder window layout; for build servers with no desktop
-y, --yes            non-interactive: no prompts
-h, --help           show help (also: make-a-dmg help)
```

A name typed without `.dmg` gets it added, and a missing output folder is created. If the path you give `--background` or `--icon` is not there, a picker opens so you can choose the file instead of starting over — unless you passed `-y`, where it just fails.

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
make-a-dmg MyApp.app --icon brand/icon.png --app-version 2.1.0

# fully unattended (for CI or scripts)
make-a-dmg MyApp.app -y --sha256 -o dist/MyApp.dmg
```

---

## Signing (optional)

If you ship your app outside the App Store, you can have the dmg signed with your Developer ID. It is **opt-in** — nothing is ever signed unless you ask.

```sh
make-a-dmg MyApp.app --sign                      # use your one Developer ID
make-a-dmg MyApp.app --sign "KodeElite"          # or name it (a partial name is fine)
```

Bare `--sign` uses your identity when you have exactly one. With several, you pick with the arrow keys:

```
   Signing identity  · ↑↓ move · Enter picks · q skips
   ❯ Developer ID Application: Azhar Ali (TEAM111)
     Apple Development: azhar@example.com (86ZY9JTWSR)  ! not for distribution
     don't sign
```

Every identity in your keychain is listed. Anything that is not a **Developer ID** is flagged, because those sign fine but do nothing for Gatekeeper — good for testing and internal builds, not for a public download. The flag follows through to the build plan and to a warning before it signs.

Every picker has a way out: `q`, or select **don't sign**. You are never stuck in a menu.

Give it a name and a partial is fine, it expands to the full identity and shows you what it resolved to before building. If the name matches nothing, or matches more than one, you get the same picker rather than an error.

Under `-y` there is nobody to ask, so an unmatched or ambiguous name fails immediately, before anything is built. The `-i` wizard shows the picker too, defaulting to **don't sign**, and only when you actually have an identity installed.

You need a **Developer ID Application** certificate, which comes with a paid Apple Developer account. Check what you have:

```sh
security find-identity -v -p codesigning
```

`Apple Development` certificates do not count — those are for local builds and TestFlight, and Gatekeeper ignores them for direct downloads.

**Signing the dmg is not the whole job.** Sign your `.app` *before* packaging it, and notarize the dmg *after*. Notarization uploads to Apple and waits on their servers, so it is deliberately left out of this tool — run it yourself:

```sh
xcrun notarytool submit MyApp-1.0.0.dmg --keychain-profile "AC" --wait
xcrun stapler staple MyApp-1.0.0.dmg
```

---

## How it works

Everything is done with tools that ship with macOS: `hdiutil` builds and compresses the disk image, `osascript` (Finder) lays out the window, and `sips` + `iconutil` prepare the icon and fit the background. An `/Applications` symlink is the drag target. The image work happens before the disk image is assembled, and the layout step verifies Finder actually saved the window and retries if it did not.

```
your.app ─┐
          ├─► staging folder ─► hdiutil create ─► mount ─► Finder lays out ─► detach ─► compress ─► sign ─► .dmg
bg / icon ─┘                     (read-write)              window + icons              (UDZO)   (optional)
```

The window layout is a **snapshot**, not code. Finder saves it into a hidden `.DS_Store` inside the image, and replays it when someone else mounts the dmg. Nothing of ours runs on their Mac, so the layout cannot adapt to their screen or their Finder settings — which is why backgrounds want some breathing room at the edges.

---

## Troubleshooting

**The first run asks to control Finder.** Styling the window uses Finder, so macOS shows "Terminal wants to control Finder" once. Allow it (System Settings > Privacy & Security > Automation). If you decline, the dmg still builds, just without the laid-out window.

**My app has no custom disk icon.** Apps that keep their icon only in an asset catalog have no standalone `.icns` to read. Pass one with `--icon your.png` (a PNG is converted for you).

**It says the icon cannot be attached.** Setting a disk icon needs `SetFile` and `Rez`, which come with the Xcode command line tools. Everything else works without them; run `xcode-select --install` if you want the icon.

**The background looks cut off at the bottom on my Mac.** Check Finder → View → **Hide Tab Bar**. The tab bar is a setting on your machine, not part of the dmg, and it takes roughly 36 points off the visible area. It is off by default, so people downloading your app almost certainly do not have it.

**Gatekeeper warns when opening the app.** This tool packages your app as-is. An unsigned, un-notarized app still warns on first open, and `--sign` on the dmg does not fix that on its own, the app inside has to be signed and the dmg notarized. See [Signing](#signing-optional).

---

## Requirements

macOS only. Uses `hdiutil`, `osascript`, `sips`, `iconutil`, all built in. No Homebrew, no third-party tools.

---

## Testing

A self-contained smoke test creates its own throwaway app and backgrounds, builds real disk images, mounts them and checks what is inside.

```sh
./test.sh          # quick: one build plus every instant check   ~16s
./test.sh --full   # everything, eight builds                    ~2m
```

```
==== 18 passed, 0 failed ====
```

It exits non-zero on failure, so it works as a release gate. CI runs `--full` on every push. See **[TESTING.md](TESTING.md)** for what each check guards against, what is deliberately left out, and the manual checks worth doing before a release.

---

## Contributing

Bug reports and fixes are welcome. One rule: **it stays a single file** — the run-from-the-web one-liner only works because there is exactly one. See **[CONTRIBUTING.md](CONTRIBUTING.md)** before opening a pull request.

---

## License

MIT. See [LICENSE](LICENSE).

Made by [KodeElite](https://kodeelite.com).
