"""System tray icon: quick access to every capture mode, history and settings."""
from __future__ import annotations

from PyQt6.QtGui import QIcon
from PyQt6.QtWidgets import QApplication, QMenu, QStyle, QSystemTrayIcon

from snapshare.capture.spectacle import CaptureMode


class TrayIcon(QSystemTrayIcon):
    def __init__(self, controller) -> None:
        icon = QIcon.fromTheme("camera-photo")
        if icon.isNull():
            icon = QApplication.style().standardIcon(QStyle.StandardPixmap.SP_ComputerIcon)
        super().__init__(icon)
        self.controller = controller
        self.setToolTip("Snapshare")

        menu = QMenu()
        menu.addAction("Capture Region", lambda: controller.start_capture(CaptureMode.REGION))
        menu.addAction("Capture Full Screen", lambda: controller.start_capture(CaptureMode.FULLSCREEN))
        menu.addAction("Capture Active Window", lambda: controller.start_capture(CaptureMode.ACTIVE_WINDOW))
        menu.addAction("Capture Current Monitor", lambda: controller.start_capture(CaptureMode.CURRENT_MONITOR))
        menu.addAction("Capture Window Under Cursor", lambda: controller.start_capture(CaptureMode.WINDOW_UNDER_CURSOR))
        menu.addSeparator()
        menu.addAction("Upload History…", controller.show_history)
        menu.addAction("Settings…", controller.show_settings)
        menu.addSeparator()
        menu.addAction("Quit", controller.quit)
        self.setContextMenu(menu)

        self.activated.connect(self._on_activated)

    def _on_activated(self, reason: QSystemTrayIcon.ActivationReason) -> None:
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            self.controller.start_capture(CaptureMode.REGION)
