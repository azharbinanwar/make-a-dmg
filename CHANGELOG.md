# Changelog

All notable changes to this project are documented here.
This project follows [Semantic Versioning](https://semver.org/), and the format
follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] — 2026-08-06

First public release.

`make-a-dmg` turns a macOS `.app` into a polished, drag-to-install `.dmg` using
nothing but tools that ship with macOS. No Homebrew, no `create-dmg`, nothing to
install. It is a single file, so it can either run straight from the web or be
installed:

```sh
bash <(curl -fsSL kodeelite.com/dmg)          # run it online, installs nothing
brew install azharbinanwar/tap/make-a-dmg     # or install it
```

### Packaging

- Finds the app from an argument, from the current folder, or through a file
  picker when there is nothing obvious to use.
- Reads the version from the bundle and names the output `<App>-<version>.dmg`.
- Adds an `/Applications` symlink as the drag target.
- Pulls the disk icon from the app's own `.icns` automatically, or takes one via
  `--icon` (a PNG is converted for you).
- Compresses to UDZO, and can write a `.sha256` alongside with `--sha256`.

### Window and background

- Lays out the Finder window with the app on the left and Applications on the
  right, sized and positioned however you like.
- Backgrounds from an image or from a hex color (`--background 1e1e1e`), so a
  plain background needs no image editor.
- Four fit modes — `crop`, `contain`, `stretch`, `window` — with the window size
  always respected unless you explicitly ask it to match the image.
- Retina support: a `@2x` sibling, or a single image already at least twice the
  window, is kept at double pixels and tagged 144 dpi so it stays sharp.
- The window is built to give the background the drawing area you actually asked
  for, and the path bar, status bar and toolbar are switched off inside the dmg.

### Signing

- `--sign [IDENTITY]` signs the finished dmg with a Developer ID. Bare `--sign`
  uses your identity when you have one, or lists them to choose from.
- Nothing is ever signed unless you ask.
- Identities that are not a Developer ID are flagged as unfit for distribution —
  in the picker, in the build plan, and again before signing — because they sign
  successfully but do nothing for Gatekeeper.
- Signing is resolved before the build, so a wrong identity costs a second
  rather than a full compress.

### Interface

- A guided wizard (`-i`) that walks every option, with arrow-key pickers for the
  background, the fit mode and the signing identity. Every picker has a way out.
- A build plan you confirm before anything is written, showing full paths so a
  file chosen through a picker can be identified.
- `--version` reports which version you have, and it is shown on every run.
  The app's own version is overridden with `--app-version`.
- `-y` for unattended use in CI and scripts, and `--no-window` to skip the
  Finder layout on a build server with no desktop session.
- Pickers fall back to numbered input when stdin is not a terminal, so scripted
  and piped use behaves predictably.

### Reliability

- Options are validated up front with messages that name the problem, rather
  than failing partway through a build.
- Bad paths offer a picker instead of stopping.
- The tool never silently succeeds: a background it cannot read, an icon it
  cannot build, and a signature it cannot apply are all reported.
- Temporary files and mounted volumes are cleaned up on any exit, including
  failure, and only volumes this tool mounted are ever detached.
- A self-contained test suite (`./test.sh`, 17 checks) builds real disk images
  and verifies them, and runs on every push via GitHub Actions.

### Requirements

macOS only. Uses `hdiutil`, `osascript`, `sips`, `iconutil`, `PlistBuddy`,
`security` and `codesign`, all built in. `SetFile` and `Rez` from the Xcode
command line tools are used for the disk icon when present, and their absence is
reported rather than silently ignored.

[1.0.0]: https://github.com/azharbinanwar/make-a-dmg/releases/tag/v1.0.0
