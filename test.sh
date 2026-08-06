#!/usr/bin/env bash
# test.sh: smoke test for make-a-dmg. Self-contained, creates its own throwaway
# .app and background, builds real dmgs, and checks the deterministic behavior
# (valid image, contents, naming, checksum, background fit). It does NOT check
# the Finder window styling (.DS_Store), which needs GUI automation and would
# false-fail on headless CI. Run it before releasing:  ./test.sh
set -u
BIN="$(cd "$(dirname "$0")" && pwd)/make-a-dmg"
[ -x "$BIN" ] || { echo "make-a-dmg not found or not executable next to test.sh"; exit 2; }

WORK="$(mktemp -d)"
# Detach anything still mounted from a dmg under $WORK, so a run that dies
# halfway does not leave volumes behind in /Volumes.
cleanup(){
  hdiutil info 2>/dev/null | awk -v w="$WORK" '
    /^image-path/ { p=substr($0, index($0,":")+2); next }
    index($0,"/Volumes/") && index(p,w)==1 { print substr($0, index($0,"/Volumes/")) }' \
  | while IFS= read -r m; do hdiutil detach "$m" -force -quiet 2>/dev/null; done
  rm -rf "$WORK"
}
trap cleanup EXIT
pass=0; fail=0
ok(){ printf "  ok   %s\n" "$1"; pass=$((pass+1)); }
no(){ printf "  FAIL %s\n" "$1"; fail=$((fail+1)); }
mount_dmg(){ hdiutil attach "$1" -nobrowse -noautoopen 2>/dev/null | grep -o '/Volumes/.*' | tail -1; }
bg_dims(){ local M f d; M="$(mount_dmg "$1")"; f="$(ls "$M"/.background/* 2>/dev/null | head -1)"
  d="$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | awk '/pixel/{print $2}' | paste -sd'x' -)"
  hdiutil detach "$M" -quiet 2>/dev/null; printf '%s' "$d"; }

# --- fixtures: a minimal .app and an 800x600 background ---
APP="$WORK/DemoApp.app"
mkdir -p "$APP/Contents"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.0" "$APP/Contents/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c "Add :CFBundleName string DemoApp"            "$APP/Contents/Info.plist" >/dev/null
B64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
{ printf '%s' "$B64" | base64 -D 2>/dev/null || printf '%s' "$B64" | base64 --decode; } > "$WORK/px.png"
sips --padToHeightWidth 600 800 --padColor 3366AA "$WORK/px.png" --out "$WORK/bg.png" >/dev/null 2>&1

echo "running make-a-dmg smoke tests..."

# 1) default build: valid image + contents
"$BIN" "$APP" -y -o "$WORK/a.dmg" >/dev/null 2>&1
{ [ -f "$WORK/a.dmg" ] && hdiutil imageinfo "$WORK/a.dmg" >/dev/null 2>&1; } && ok "builds a valid dmg" || no "builds a valid dmg"
M="$(mount_dmg "$WORK/a.dmg")"
{ [ -d "$M/DemoApp.app" ] && [ -L "$M/Applications" ]; } && ok "contains the app + Applications link" || no "contains app + Applications link"
hdiutil detach "$M" -quiet 2>/dev/null

# 2) default output name follows app + version
mkdir -p "$WORK/nd"; ( cd "$WORK/nd" && "$BIN" "$APP" -y >/dev/null 2>&1 )
[ -f "$WORK/nd/DemoApp-1.0.0.dmg" ] && ok "default name is <App>-<version>.dmg" || no "default output name"

# 3) bare output name gets .dmg + subdir created; checksum + custom volume name
"$BIN" "$APP" -y --sha256 --volname "Demo Vol" -o "$WORK/out/custom" >/dev/null 2>&1
[ -f "$WORK/out/custom.dmg" ] && ok "adds .dmg and creates the output folder" || no ".dmg extension / subdir"
( cd "$WORK/out" && shasum -a 256 -c custom.dmg.sha256 >/dev/null 2>&1 ) && ok "--sha256 checksum verifies" || no "sha256 verifies"
M="$(mount_dmg "$WORK/out/custom.dmg")"
case "$M" in *"Demo Vol") ok "--volname sets the volume name" ;; *) no "volume name ($M)" ;; esac
hdiutil detach "$M" -quiet 2>/dev/null

# 4) version override shows in the name
mkdir -p "$WORK/vd"; ( cd "$WORK/vd" && "$BIN" "$APP" -y --app-version 9.9.9 >/dev/null 2>&1 )
[ -f "$WORK/vd/DemoApp-9.9.9.dmg" ] && ok "--app-version overrides the name" || no "app version override name"

# 4b) --version reports the tool's own version, and does not build anything
case "$("$BIN" --version 2>&1)" in
  "make-a-dmg "[0-9]*) ok "--version reports the tool version" ;;
  *) no "--version reports the tool version" ;;
esac

# 5) background: crop fits the image to the window (default 660x500)
"$BIN" "$APP" -y --background "$WORK/bg.png" -o "$WORK/crop.dmg" >/dev/null 2>&1
[ "$(bg_dims "$WORK/crop.dmg")" = "660x500" ] && ok "crop fits background to the window" || no "crop background size"

# 6) background: --fit window sizes the window to the image (800x600)
"$BIN" "$APP" -y --background "$WORK/bg.png" --fit window -o "$WORK/win.dmg" >/dev/null 2>&1
[ "$(bg_dims "$WORK/win.dmg")" = "800x600" ] && ok "--fit window uses the image size" || no "fit window size"

# 7) --no-icon still builds a valid dmg
"$BIN" "$APP" -y --no-icon -o "$WORK/ni.dmg" >/dev/null 2>&1
{ [ -f "$WORK/ni.dmg" ] && hdiutil imageinfo "$WORK/ni.dmg" >/dev/null 2>&1; } && ok "--no-icon builds a valid dmg" || no "--no-icon build"

# 8) an invalid --fit is rejected
if "$BIN" "$APP" -y --fit bogus -o "$WORK/bad.dmg" >/dev/null 2>&1; then no "rejects an invalid --fit"; else ok "rejects an invalid --fit"; fi

# 9) an unknown signing identity fails, and fails before building anything
if "$BIN" "$APP" -y --sign "No Such Identity 0000" -o "$WORK/sg.dmg" >/dev/null 2>&1
then no "rejects an unknown signing identity"
else [ -f "$WORK/sg.dmg" ] && no "bails out before building" || ok "rejects an unknown signing identity"; fi

# 10) signing is opt-in: a default build is left unsigned
if codesign -dv "$WORK/a.dmg" >/dev/null 2>&1; then no "default build stays unsigned"; else ok "default build stays unsigned"; fi

# 11) --help works off a consumed pipe (the `bash <(curl ...)` path) and leaks no source
H="$(bash <(cat "$BIN") --help 2>&1)"
case "$H" in
  "make-a-dmg "*": turn a macOS"*) case "$H" in *"set -euo pipefail"*) no "--help leaks source lines" ;;
                                                *) ok "--help works over a pipe, no source leak" ;; esac ;;
  *) no "--help over a pipe" ;;
esac

# 12) bad numeric options are rejected instead of crashing bash
nf=0
for bad in "--window-size abc" "--icon-size foo" "--app-pos hi" "--drop-pos 1,2,3"; do
  set -- $bad
  out="$("$BIN" "$APP" -y "$1" "$2" -o "$WORK/bad.dmg" 2>&1)" && nf=$((nf+1))
  case "$out" in *"unbound variable"*|*"syntax error"*) nf=$((nf+1)) ;; esac
done
[ "$nf" -eq 0 ] && ok "rejects bad numeric options cleanly" || no "bad numeric options ($nf leaked)"

# 13) an option with no value is reported, not left to bash
if "$BIN" "$APP" -y --volname 2>&1 | grep -q "needs a value"; then ok "reports a missing option value"; else no "missing option value"; fi

# 14) a quote in the volume name does not break the build
"$BIN" "$APP" -y --volname 'My "Cool" App' -o "$WORK/q.dmg" >/dev/null 2>&1
M="$(mount_dmg "$WORK/q.dmg")"
case "$M" in *'My "Cool" App'*) ok "a quoted volume name survives" ;; *) no "quoted volume name ($M)" ;; esac
hdiutil detach "$M" -quiet 2>/dev/null

echo ""
echo "==== $pass passed, $fail failed ===="
[ "$fail" -eq 0 ]
