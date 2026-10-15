#!/usr/bin/env bash
# Builds a distributable WidgetsBoard.plasmoid file.
# A .plasmoid is just a zip of the package/ contents with metadata.json at the root.
# Users can install it by double-clicking, or with:
#   kpackagetool6 --type Plasma/Applet --install WidgetsBoard.plasmoid
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/WidgetsBoard.plasmoid"

cd "$HERE/package"
rm -f "$OUT"

if command -v zip >/dev/null 2>&1; then
    zip -r -q "$OUT" . -x '*.DS_Store'
else
    echo "error: 'zip' is required to build the .plasmoid file." >&2
    exit 1
fi

echo "Built: $OUT"
echo
echo "Install it by double-clicking the file, or run:"
echo "  kpackagetool6 --type Plasma/Applet --install \"$OUT\""
