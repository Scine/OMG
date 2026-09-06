"""CLI entry point.

Typical usage on KDE:

    snapshare tray                     # persistent tray icon (autostart this)
    snapshare capture --mode region    # bind to a global shortcut (e.g. PrtScn)
    snapshare history                  # open the upload history browser
    snapshare settings                 # open the settings dialog

Because Wayland forbids ordinary applications from grabbing global hotkeys,
bind the `capture` invocations to keys via KDE System Settings -> Shortcuts ->
Custom Shortcuts, rather than expecting Snapshare to register them itself.
"""
from __future__ import annotations

import argparse
import sys

from snapshare.capture.spectacle import CaptureMode


def _run_tray() -> int:
    from snapshare.app import Controller, build_app

    app = build_app()
    controller = Controller(app, quit_after_capture=False)
    controller.install_tray()
    return app.exec()


def _run_capture(mode_name: str) -> int:
    from snapshare.app import Controller, build_app

    app = build_app()
    controller = Controller(app, quit_after_capture=True)
    controller.start_capture(CaptureMode(mode_name))
    return app.exec()


def _run_history() -> int:
    from snapshare.app import build_app
    from snapshare.history.window import HistoryWindow

    app = build_app()
    app.setQuitOnLastWindowClosed(True)
    window = HistoryWindow()
    window.show()
    return app.exec()


def _run_settings() -> int:
    from snapshare.app import build_app
    from snapshare.settings_dialog import SettingsDialog

    app = build_app()
    dialog = SettingsDialog()
    dialog.exec()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(prog="snapshare", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("tray", help="Run the persistent system tray icon")

    capture_parser = subparsers.add_parser("capture", help="Take a single screenshot and open the editor")
    capture_parser.add_argument(
        "--mode",
        choices=[m.value for m in CaptureMode],
        default=CaptureMode.REGION.value,
    )

    subparsers.add_parser("history", help="Browse upload history")
    subparsers.add_parser("settings", help="Open settings")

    args = parser.parse_args()
    command = args.command or "tray"

    if command == "tray":
        return _run_tray()
    if command == "capture":
        return _run_capture(args.mode)
    if command == "history":
        return _run_history()
    if command == "settings":
        return _run_settings()

    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
