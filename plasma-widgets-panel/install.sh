#!/usr/bin/env bash
# Installer for the "Widgets Board" Plasma 6 applet.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$HERE/package"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "error: kpackagetool6 not found. Install KDE Plasma 6 developer tools:" >&2
    echo "  Fedora/openSUSE: kpackage  |  Arch: kpackage  |  Debian/Ubuntu: kpackagetool6" >&2
    exit 1
fi

ID="org.kde.widgetsboard"

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -qx "$ID"; then
    echo "Upgrading existing $ID ..."
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG"
else
    echo "Installing $ID ..."
    kpackagetool6 --type Plasma/Applet --install "$PKG"
fi

echo
echo "Done. To add it to your panel:"
echo "  1. Right-click your panel -> 'Add or Manage Widgets…'"
echo "  2. Search for 'Widgets Board' and drag it onto the panel."
echo "     (Tip: place it at the far left or right corner for the Windows 11 feel.)"
echo
echo "If it doesn't appear immediately, restart Plasma:"
echo "  kquitapp6 plasmashell && kstart plasmashell"
