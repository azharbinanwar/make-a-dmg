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

## Reporting a bug

Include your macOS version, the exact command you ran, and the full output. If
it is a window layout problem, a screenshot of the mounted dmg is worth more
than any description.
