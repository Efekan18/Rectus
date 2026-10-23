#!/bin/bash
# Builds and packages Rectus.app.
#   ./build.sh            -> build/Rectus.app
#   ./build.sh --install  -> also installs to ~/Applications and launches it
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Rectus.app"

echo "→ Building (release)"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/Rectus"

echo "→ Packaging: $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/Rectus"
cp Resources/Info.plist "$APP/Contents/Info.plist"

echo "→ Signing (ad-hoc)"
codesign --force --sign - "$APP"

if [[ "${1:-}" == "--install" ]]; then
    DEST="$HOME/Applications/Rectus.app"
    echo "→ Installing: $DEST"
    pkill -x Rectus 2>/dev/null || true
    mkdir -p "$HOME/Applications"
    rm -rf "$DEST"
    cp -R "$APP" "$DEST"
    open "$DEST"
fi

echo "✓ Done"
