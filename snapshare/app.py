"""Application bootstrap and the glue between capture, editor, upload and tray."""
from __future__ import annotations

import sys

from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtGui import QPixmap
from PyQt6.QtWidgets import QApplication, QMessageBox, QSystemTrayIcon

from snapshare.capture.spectacle import (
    CaptureCancelled,
    CaptureMode,
    SpectacleNotFoundError,
    capture,
)
from snapshare.config import get_config
from snapshare.editor.window import EditorWindow, UploadThread
from snapshare.history.window import HistoryWindow
from snapshare.settings_dialog import SettingsDialog
from snapshare.tray import TrayIcon


class CaptureThread(QThread):
    succeeded = pyqtSignal(str)
    cancelled = pyqtSignal()
    failed = pyqtSignal(str)

    def __init__(self, mode: CaptureMode) -> None:
        super().__init__()
        self._mode = mode

    def run(self) -> None:
        try:
            path = capture(self._mode)
            self.succeeded.emit(str(path))
        except CaptureCancelled:
            self.cancelled.emit()
        except SpectacleNotFoundError as exc:
            self.failed.emit(str(exc))
        except Exception as exc:  # noqa: BLE001
            self.failed.emit(f"Unexpected capture error: {exc}")


class Controller:
    """Owns long-lived windows/threads so they aren't garbage collected mid-flight."""

    def __init__(self, app: QApplication, quit_after_capture: bool = False) -> None:
        self.app = app
        self.config = get_config()
        self.quit_after_capture = quit_after_capture

        self.tray: TrayIcon | None = None
        self._capture_thread: CaptureThread | None = None
        self._editor_windows: list[EditorWindow] = []
        self._history_window: HistoryWindow | None = None
        self._quick_upload_thread: UploadThread | None = None

    def install_tray(self) -> None:
        if not QSystemTrayIcon.isSystemTrayAvailable():
            return
        self.tray = TrayIcon(self)
        self.tray.show()

    def start_capture(self, mode: CaptureMode) -> None:
        self._capture_thread = CaptureThread(mode)
        self._capture_thread.succeeded.connect(self._on_capture_succeeded)
        self._capture_thread.cancelled.connect(self._on_capture_cancelled)
        self._capture_thread.failed.connect(self._on_capture_failed)
        self._capture_thread.start()

    def _notify(self, title: str, message: str) -> None:
        if self.tray is not None:
            self.tray.showMessage(title, message, QSystemTrayIcon.MessageIcon.Information, 4000)

    def _on_capture_cancelled(self) -> None:
        if self.quit_after_capture:
            self.app.quit()

    def _on_capture_failed(self, message: str) -> None:
        QMessageBox.critical(None, "Capture failed", message)
        if self.quit_after_capture:
            self.app.quit()

    def _on_capture_succeeded(self, path: str) -> None:
        pixmap = QPixmap(path)

        if self.config.get("open_editor_before_upload", True):
            window = EditorWindow(pixmap)
            window.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
            window.destroyed.connect(lambda: self._forget_editor(window))
            if self.quit_after_capture:
                window.upload_finished.connect(lambda *_: None)
                window.destroyed.connect(lambda: self.app.quit())
            self._editor_windows.append(window)
            window.show()
            window.raise_()
            window.activateWindow()
            return

        # Fast path: no editor, straight to clipboard/upload.
        if self.config.get("copy_image_to_clipboard_on_close", False):
            QApplication.clipboard().setPixmap(pixmap)

        if self.config.get("auto_upload", True):
            self._quick_upload(pixmap, path)
        elif self.quit_after_capture:
            self.app.quit()

    def _quick_upload(self, pixmap: QPixmap, saved_path: str) -> None:
        from PyQt6.QtCore import QBuffer, QByteArray, QIODevice

        uploader_cfg = self.config.active_uploader()
        if not uploader_cfg:
            self._notify("Snapshare", "No uploader configured — open Settings to add one.")
            if self.quit_after_capture:
                self.app.quit()
            return

        buf = QByteArray()
        buffer = QBuffer(buf)
        buffer.open(QIODevice.OpenModeFlag.WriteOnly)
        pixmap.save(buffer, "PNG")

        self._quick_upload_thread = UploadThread(bytes(buf), uploader_cfg)
        self._quick_upload_thread.succeeded.connect(lambda result: self._on_quick_upload_succeeded(result, saved_path))
        self._quick_upload_thread.failed.connect(self._on_quick_upload_failed)
        self._quick_upload_thread.start()

    def _on_quick_upload_succeeded(self, result, saved_path: str) -> None:
        import datetime as dt

        if self.config.get("copy_url_to_clipboard", True):
            QApplication.clipboard().setText(result.url)
        self._notify("Uploaded", result.url)
        self.config.add_history_entry(
            {
                "timestamp": dt.datetime.now().isoformat(timespec="seconds"),
                "file_path": saved_path,
                "url": result.url,
                "delete_url": result.delete_url,
            }
        )
        if self.quit_after_capture:
            self.app.quit()

    def _on_quick_upload_failed(self, message: str) -> None:
        self._notify("Upload failed", message)
        if self.quit_after_capture:
            self.app.quit()

    def _forget_editor(self, window: EditorWindow) -> None:
        if window in self._editor_windows:
            self._editor_windows.remove(window)

    def show_history(self) -> None:
        if self._history_window is None:
            self._history_window = HistoryWindow()
        self._history_window.refresh()
        self._history_window.show()
        self._history_window.raise_()
        self._history_window.activateWindow()

    def show_settings(self) -> None:
        dialog = SettingsDialog()
        dialog.exec()

    def quit(self) -> None:
        self.app.quit()


def build_app() -> QApplication:
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    app.setApplicationName("Snapshare")
    return app
