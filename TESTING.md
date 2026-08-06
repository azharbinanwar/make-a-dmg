# Testing

Two modes:

```sh
./test.sh          # quick: one build plus every instant check   ~16s
./test.sh --full   # everything, eight builds                    ~2m
```

Quick is for while you work — it still catches anything that breaks argument
handling, help, signing refusal or the build itself. **Full is what CI runs, and
what to run before a release.**

The suite creates its own throwaway `.app` and background images, builds real
disk images, mounts them, checks what is inside, and cleans up after itself.
Nothing is installed and nothing is left behind.

```
running make-a-dmg smoke tests...
  ok   builds a valid dmg
  ...
==== 18 passed, 0 failed ====
```

It exits non-zero on any failure, so it works as a release gate and in CI.

Builds pass `--no-window`, because the Finder layout cannot be verified without
a desktop session anyway and retrying it costs about seven seconds per build.

---

## What the suite covers

| # | Check | Guards against |
|---|---|---|
| 1 | Builds a valid dmg | `hdiutil` output that will not mount |
| 2 | Contains the app + `Applications` link | a dmg you cannot actually install from |
| 3 | Default name is `<App>-<version>.dmg` | version lost from the filename |
| 4 | Adds `.dmg`, creates the output folder | `-o dist/name` failing on a missing folder |
| 5 | `--sha256` verifies | a checksum that does not match its file |
| 6 | `--volname` sets the volume name | the window titled wrongly |
| 7 | `--version` overrides the name | the override being ignored |
| 8 | `crop` fits the background to the window | backgrounds the wrong size |
| 9 | `--fit window` uses the image size | window not matching the artwork |
| 10 | `--no-icon` still builds | the opt-out breaking the build |
| 11 | Rejects an invalid `--fit` | typos silently falling back to a default |
| 12 | Rejects an unknown signing identity | shipping unsigned after asking for signed |
| 13 | A default build stays unsigned | signing something without being asked |
| 14 | `--help` works over a pipe, no source leak | help being broken in the `curl` one-liner |
| 15 | Rejects bad numeric options cleanly | raw `unbound variable` crashes |
| 16 | Reports a missing option value | `--volname` with nothing after it |
| 17 | A quoted volume name survives | a `"` in a name breaking the AppleScript |
| 18 | `--version` reports the tool version | no way to tell which version is installed |

Checks that build a disk image run only under `--full`. The rest are instant and
run every time.

---

## What it does not cover, and why

**Finder window styling.** Positioning icons and applying the background needs
GUI automation and Automation permission for your terminal. On a headless CI
runner there is no desktop session, so these would fail for reasons that have
nothing to do with the code. The suite checks everything that is deterministic
and leaves the visual result to the checks below.

**Retina sharpness and background framing.** Whether a background *looks* right
is a judgement call on a real screen. The numbers are verified; the appearance is
not something a script can assert.

---

## Manual checks

These need a real screen. Worth doing before a release.

### Retina backgrounds

Verified by inspecting the image inside the built dmg:

| Input | Expected inside the dmg | Status |
|---|---|---|
| `bg.png` with a `bg@2x.png` sibling | `1320x1000 @ 144dpi` | ✅ |
| A single image already ≥2× the window | `1320x1000 @ 144dpi` | ✅ |
| A plain window-sized image | `660x500 @ 72dpi` | ✅ |
| A solid color (`--background 1e1e1e`) | `660x500 @ 72dpi` | ✅ |

Finder divides pixels by DPI to get points, so double the pixels at 144 dpi fills
the same window and stays sharp. Confirm it *looks* sharp by opening the dmg on a
retina display.

### Window framing

Build a dmg whose background has a coloured band along the top and bottom edges,
then open it and check both bands are visible:

```sh
T=$(mktemp -d)
mkdir -p "$T/Probe.app/Contents"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0" "$T/Probe.app/Contents/Info.plist" >/dev/null
sips -s format png -z 1 1 /System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns --out "$T/px.png" >/dev/null
sips --padToHeightWidth 420 660 --padColor 3366AA "$T/px.png" --out "$T/t.png"    >/dev/null
sips --padToHeightWidth 500 660 --padColor FF00FF "$T/t.png"  --out "$T/edge.png" >/dev/null
./make-a-dmg "$T/Probe.app" -y --background "$T/edge.png" --window-size 660x500 --volname EdgeTest -o "$T/edge.dmg"
```

Both magenta bands should be visible. If the bottom one is missing, check
Finder → View → **Hide Tab Bar** first — the tab bar is a setting on your own
Mac, not part of the dmg, and it hides roughly 36 points.

This check is what found the title bar bug: Finder's window `bounds` include the
title bar, so the drawing area was 28 points shorter than requested and every
background lost its bottom strip. The window is now built 28 points taller to
compensate.

### The release asset

The published install URL has no version in it:

```sh
curl -fsSL https://github.com/azharbinanwar/make-a-dmg/releases/latest/download/make-a-dmg | head -1
```

That must print `#!/usr/bin/env bash`. GitHub resolves `latest` to the newest
release and serves the asset attached to it, so a release without the script
attached breaks the install command for everyone. `.github/workflows/release.yml`
attaches it on every tag; this check confirms it worked.

### Signing

Needs a Developer ID in your keychain:

```sh
./make-a-dmg MyApp.app -y --sign -o /tmp/signed.dmg
codesign -dv /tmp/signed.dmg
codesign --verify --verbose /tmp/signed.dmg
```

Expect `valid on disk` and `satisfies its Designated Requirement`, plus a
`Timestamp` line. Without a timestamp the signature cannot be notarised.

---

## Continuous integration

`.github/workflows/test.yml` runs two jobs in parallel on every push and pull
request:

- **lint** on `ubuntu-latest` — `shellcheck --severity=warning`. Static analysis
  needs no macOS, and keeping it on Linux is faster.
- **test** on `macos-latest` — `./test.sh --full`. A macOS runner is required
  here; the entire tool is `hdiutil`, `sips`, `iconutil` and `osascript`.
