"""Capture backend that shells out to KDE's Spectacle, which already speaks
the correct portal/KWin protocol for screenshots under Wayland.
"""
from __future__ import annotations

import shutil
import subprocess
import tempfile
from enum import Enum
from pathlib import Path


class CaptureMode(str, Enum):
    REGION = "region"
    FULLSCREEN = "fullscreen"
    ACTIVE_WINDOW = "active"
    CURRENT_MONITOR = "monitor"
    WINDOW_UNDER_CURSOR = "window"

    @property
    def spectacle_flag(self) -> str:
        return {
            CaptureMode.REGION: "-r",
            CaptureMode.FULLSCREEN: "-f",
            CaptureMode.ACTIVE_WINDOW: "-a",
            CaptureMode.CURRENT_MONITOR: "-m",
            CaptureMode.WINDOW_UNDER_CURSOR: "-w",
        }[self]


class SpectacleNotFoundError(RuntimeError):
    pass


class CaptureCancelled(RuntimeError):
    """Raised when the user aborted an interactive capture (e.g. pressed Escape)."""


def is_available() -> bool:
    return shutil.which("spectacle") is not None


def capture(mode: CaptureMode, delay_ms: int = 0) -> Path:
    """Run spectacle in background mode and return the path to the saved PNG.

    Raises SpectacleNotFoundError if spectacle isn't installed, or
    CaptureCancelled if the user backed out of an interactive region/window
    selection.
    """
    if not is_available():
        raise SpectacleNotFoundError(
            "The 'spectacle' command was not found. Install it with "
            "'sudo pacman -S spectacle' (Arch) or 'sudo apt install kde-spectacle' "
            "(Kubuntu)."
        )

    out_file = Path(tempfile.mkstemp(prefix="snapshare-", suffix=".png")[1])
    out_file.unlink(missing_ok=True)

    cmd = ["spectacle", "-b", "-n", mode.spectacle_flag, "-o", str(out_file)]
    if delay_ms > 0:
        cmd += ["-d", str(delay_ms)]

    # Interactive modes (region/window-under-cursor) can take an arbitrary
    # amount of time while the user drags a selection, so we don't use a
    # short timeout here.
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)

    if not out_file.exists() or out_file.stat().st_size == 0:
        # Spectacle exits 0 even when the user cancels a region selection,
        # so "no file produced" is the reliable cancellation signal.
        raise CaptureCancelled(result.stderr.strip() or "Capture was cancelled.")

    return out_file
