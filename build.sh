#!/bin/bash
# DikDur.app'i derler ve paketler.
#   ./build.sh            -> build/DikDur.app
#   ./build.sh --install  -> ayrıca ~/Applications'a kurar ve açar
set -euo pipefail
cd "$(dirname "$0")"

APP="build/DikDur.app"

echo "→ Derleniyor (release)"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/DikDur"

echo "→ Paketleniyor: $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/DikDur"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "→ İmzalanıyor (ad-hoc)"
codesign --force --sign - "$APP"

if [[ "${1:-}" == "--install" ]]; then
    DEST="$HOME/Applications/DikDur.app"
    echo "→ Kuruluyor: $DEST"
    pkill -x DikDur 2>/dev/null || true
    mkdir -p "$HOME/Applications"
    rm -rf "$DEST"
    cp -R "$APP" "$DEST"
    open "$DEST"
fi

echo "✓ Bitti"
