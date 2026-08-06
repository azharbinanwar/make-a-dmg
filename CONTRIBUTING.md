# Contributing

Thanks for looking. This is a small project with one firm rule and a short checklist.

## The one firm rule: it stays a single file

`make-a-dmg` is one executable script and it has to stay that way. The headline
use is:

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/azharbinanwar/make-a-dmg/main/make-a-dmg)
```

That works because there is exactly one file. The script arrives on a pipe with
no directory beside it, so `source lib/anything.sh` has nothing to source.
Splitting it into modules would mean either a build step that glues it back
together for release, or dropping run-from-the-web entirely.

So: **no `lib/`, no `src/`, no sourcing.** A pull request that modularises the
script will be declined no matter how tidy it is. If a section is getting hard
to follow, add a section banner and better comments.

## Constraints to keep in mind

- **macOS built-ins only.** `hdiutil`, `osascript`, `sips`, `iconutil`,
  `PlistBuddy`, `security`, `codesign`. No Homebrew, no third-party tools. If a
  feature needs a dependency, it does not belong here.
- **bash 3.2.** That is what ships with macOS, and it is what `/usr/bin/env bash`
  finds on a stock machine. No associative arrays, no `read -t 0.05`, no `${x^^}`.
- **`set -euo pipefail` is on.** Watch for `[ x ] && y` as the last line of a
  function — it returns 1 and will take the script down with it.
- **Interactive things must survive a pipe.** Menus fall back to numbered input
  when stdin is not a terminal, because `test.sh` and CI have no tty.
- **Never `die` inside `$( )`.** It only kills the subshell and lets a bad value
  through. Set a global instead, the way `find_file` does.

## Before you open a pull request

```sh
./test.sh
```

It builds real disk images from a throwaway app it creates itself, so it takes
a couple of minutes. It must print `0 failed`.

If you add a feature, add a check to `test.sh` for it. Keep the check
deterministic — no Finder window styling, no GUI automation, because those need
a desktop session and would fail on CI.

If you can, also run:

```sh
shellcheck make-a-dmg test.sh
```

## What is welcome

- Bug fixes, with a `test.sh` check that fails without the fix
- Better error messages, especially anything that currently fails silently
- Documentation fixes

## What is not

- Splitting the script into multiple files
- New dependencies
- Notarisation. It uploads to Apple and blocks for minutes; that belongs in your
  release pipeline, not in a packaging script. The README shows the two commands.
- Speculative options nobody has asked for

## Releasing

One line drives it. In `make-a-dmg`:

```bash
VERSION="1.0.1"
```

Change that, add a matching `## [1.0.1]` section to `CHANGELOG.md`, commit, push
to `main`. That is the whole release.

`.github/workflows/release.yml` then, in order:

1. Reads `VERSION`. If `v1.0.1` is already tagged it stops — ordinary commits do
   not re-release.
2. Refuses to continue unless `CHANGELOG.md` has a `## [1.0.1]` section, so a
   stray keystroke on that line cannot publish anything.
3. Runs `shellcheck` and `./test.sh --full`. Nothing is published if either fails.
4. Tags `v1.0.1`, creates the release with that changelog section as the notes,
   and attaches `make-a-dmg` to it.
5. Updates `url` and `sha256` in `Formula/make-a-dmg.rb` in the `homebrew-tap`
   repo, so `brew upgrade` works.

Deriving the tag from the file is deliberate: the two can never drift, so nobody
installs "1.0.1" and is told by `--version` that it is 1.0.0.

The published install URL carries no version:

```
https://github.com/azharbinanwar/make-a-dmg/releases/latest/download/make-a-dmg
```

GitHub resolves `latest` itself, which is why `kodeelite.com/dmg` never needs
changing when a release ships.

The tap bump needs a `TAP_TOKEN` secret on this repo — a fine-grained token with
Contents read/write on `homebrew-tap`. Everything else uses the automatic token.

## Reporting a bug

Include your macOS version, the exact command you ran, and the full output. If
it is a window layout problem, a screenshot of the mounted dmg is worth more
than any description.
