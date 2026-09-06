"""The editor window: toolbar + canvas + save/copy/upload actions."""
from __future__ import annotations

import datetime as dt
from pathlib import Path

from PyQt6.QtCore import QBuffer, QByteArray, QIODevice, QThread, Qt, pyqtSignal
from PyQt6.QtGui import QAction, QActionGroup, QColor, QIcon, QKeySequence, QPixmap
from PyQt6.QtWidgets import (
    QCheckBox,
    QColorDialog,
    QFileDialog,
    QLabel,
    QMainWindow,
    QMessageBox,
    QSpinBox,
    QStyle,
    QToolBar,
    QWidget,
)

from snapshare.config import get_config
from snapshare.editor.canvas import EditorScene, EditorView, Tool
from snapshare.uploaders.manager import UploadError, UploadResult, upload_with_config

PALETTE = ["#ff3b30", "#ff9500", "#ffcc00", "#34c759", "#0a84ff", "#5e5ce6", "#000000", "#ffffff"]


class UploadThread(QThread):
    succeeded = pyqtSignal(object)
    failed = pyqtSignal(str)

    def __init__(self, image_bytes: bytes, uploader_config: dict) -> None:
        super().__init__()
        self._image_bytes = image_bytes
        self._uploader_config = uploader_config

    def run(self) -> None:
        try:
            result: UploadResult = upload_with_config(self._uploader_config, self._image_bytes)
            self.succeeded.emit(result)
        except UploadError as exc:
            self.failed.emit(str(exc))
        except Exception as exc:  # noqa: BLE001
            self.failed.emit(f"Unexpected error: {exc}")


class EditorWindow(QMainWindow):
    upload_finished = pyqtSignal(object)

    def __init__(self, pixmap: QPixmap, on_history_entry=None) -> None:
        super().__init__()
        self.setWindowTitle("Snapshare — Editor")
        self.config = get_config()
        self._on_history_entry = on_history_entry
        self._upload_thread: UploadThread | None = None

        self.scene = EditorScene(pixmap)
        self.view = EditorView(self.scene)
        self.setCentralWidget(self.view)

        self._build_toolbar()
        self.resize(min(1200, pixmap.width() + 40), min(900, pixmap.height() + 120))

    # ------------------------------------------------------------------
    def _build_toolbar(self) -> None:
        tb = QToolBar("Tools")
        tb.setMovable(False)
        self.addToolBar(Qt.ToolBarArea.TopToolBarArea, tb)

        tool_group = QActionGroup(self)
        tool_group.setExclusive(True)

        def add_tool(name: str, tool: Tool, checked: bool = False) -> QAction:
            action = QAction(name, self)
            action.setCheckable(True)
            action.setChecked(checked)
            action.triggered.connect(lambda: self.view.set_tool(tool))
            tool_group.addAction(action)
            tb.addAction(action)
            return action

        add_tool("Select", Tool.SELECT, checked=True)
        add_tool("Pen", Tool.PEN)
        add_tool("Line", Tool.LINE)
        add_tool("Arrow", Tool.ARROW)
        add_tool("Rect", Tool.RECT)
        add_tool("Ellipse", Tool.ELLIPSE)
        add_tool("Highlight", Tool.HIGHLIGHT)
        add_tool("Text", Tool.TEXT)
        add_tool("Step #", Tool.STEP)
        add_tool("Pixelate", Tool.PIXELATE)
        add_tool("Blur", Tool.BLUR)
        add_tool("Crop", Tool.CROP)

        tb.addSeparator()

        self.color_button = QAction("Color", self)
        self._current_color = QColor(PALETTE[0])
        self._set_color_icon()
        self.color_button.triggered.connect(self._pick_color)
        tb.addAction(self.color_button)

        for hex_color in PALETTE:
            action = QAction(self)
            action.setIcon(self._swatch_icon(QColor(hex_color)))
            action.triggered.connect(lambda checked=False, c=hex_color: self._apply_color(QColor(c)))
            tb.addAction(action)

        tb.addSeparator()
        tb.addWidget(QLabel(" Width "))
        self.width_spin = QSpinBox()
        self.width_spin.setRange(1, 40)
        self.width_spin.setValue(4)
        self.width_spin.valueChanged.connect(self.view.set_stroke_width)
        tb.addWidget(self.width_spin)

        self.fill_checkbox = QCheckBox("Fill")
        self.fill_checkbox.toggled.connect(self.view.set_fill_shapes)
        tb.addWidget(self.fill_checkbox)

        tb.addSeparator()

        undo_action = QAction("Undo", self)
        undo_action.setShortcut(QKeySequence.StandardKey.Undo)
        undo_action.triggered.connect(self.view.undo)
        tb.addAction(undo_action)

        redo_action = QAction("Redo", self)
        redo_action.setShortcut(QKeySequence.StandardKey.Redo)
        redo_action.triggered.connect(self.view.redo)
        tb.addAction(redo_action)

        clear_crop_action = QAction("Clear Crop", self)
        clear_crop_action.triggered.connect(self.view.clear_crop)
        tb.addAction(clear_crop_action)

        tb.addSeparator()

        save_action = QAction("Save", self)
        save_action.setShortcut(QKeySequence.StandardKey.Save)
        save_action.triggered.connect(self.save_to_disk)
        tb.addAction(save_action)

        save_as_action = QAction("Save As…", self)
        save_as_action.triggered.connect(self.save_as)
        tb.addAction(save_as_action)

        copy_action = QAction("Copy", self)
        copy_action.setShortcut(QKeySequence.StandardKey.Copy)
        copy_action.triggered.connect(self.copy_to_clipboard)
        tb.addAction(copy_action)

        self.upload_action = QAction("Upload", self)
        self.upload_action.setShortcut(QKeySequence("Ctrl+Return"))
        self.upload_action.triggered.connect(self.upload)
        tb.addAction(self.upload_action)

    def _swatch_icon(self, color: QColor) -> QIcon:
        pm = QPixmap(20, 20)
        pm.fill(color)
        return QIcon(pm)

    def _set_color_icon(self) -> None:
        self.color_button.setIcon(self._swatch_icon(self._current_color))

    def _apply_color(self, color: QColor) -> None:
        self._current_color = color
        self.view.set_color(color)
        self._set_color_icon()

    def _pick_color(self) -> None:
        color = QColorDialog.getColor(self._current_color, self, "Annotation Color")
        if color.isValid():
            self._apply_color(color)

    # -- export helpers -------------------------------------------------
    def _final_pixmap(self) -> QPixmap:
        return self.view.render_final_pixmap()

    def _final_png_bytes(self) -> bytes:
        pixmap = self._final_pixmap()
        buf = QByteArray()
        buffer = QBuffer(buf)
        buffer.open(QIODevice.OpenModeFlag.WriteOnly)
        pixmap.save(buffer, "PNG")
        return bytes(buf)

    def _default_filename(self) -> Path:
        save_dir = Path(self.config.get("save_directory"))
        save_dir.mkdir(parents=True, exist_ok=True)
        timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        return save_dir / f"snapshare_{timestamp}.png"

    # -- actions ----------------------------------------------------------
    def save_to_disk(self) -> Path:
        path = self._default_filename()
        self._final_pixmap().save(str(path), "PNG")
        self.statusBar().showMessage(f"Saved to {path}", 4000)
        return path

    def save_as(self) -> None:
        default = str(self._default_filename())
        path_str, _ = QFileDialog.getSaveFileName(self, "Save Screenshot", default, "PNG Images (*.png)")
        if path_str:
            self._final_pixmap().save(path_str, "PNG")
            self.statusBar().showMessage(f"Saved to {path_str}", 4000)

    def copy_to_clipboard(self) -> None:
        from PyQt6.QtWidgets import QApplication

        QApplication.clipboard().setPixmap(self._final_pixmap())
        self.statusBar().showMessage("Copied image to clipboard", 3000)

    def upload(self) -> None:
        uploader_cfg = self.config.active_uploader()
        if not uploader_cfg:
            QMessageBox.warning(self, "No uploader configured", "Configure an uploader in Settings first.")
            return

        saved_path = self.save_to_disk()
        image_bytes = self._final_png_bytes()

        self.upload_action.setEnabled(False)
        self.statusBar().showMessage("Uploading…")

        self._upload_thread = UploadThread(image_bytes, uploader_cfg)
        self._upload_thread.succeeded.connect(lambda result: self._on_upload_succeeded(result, saved_path))
        self._upload_thread.failed.connect(self._on_upload_failed)
        self._upload_thread.start()

    def _on_upload_succeeded(self, result: UploadResult, saved_path: Path) -> None:
        from PyQt6.QtWidgets import QApplication

        self.upload_action.setEnabled(True)
        if self.config.get("copy_url_to_clipboard", True):
            QApplication.clipboard().setText(result.url)
        self.statusBar().showMessage(f"Uploaded: {result.url} (copied to clipboard)", 8000)

        entry = {
            "timestamp": dt.datetime.now().isoformat(timespec="seconds"),
            "file_path": str(saved_path),
            "url": result.url,
            "delete_url": result.delete_url,
        }
        self.config.add_history_entry(entry)
        if self._on_history_entry:
            self._on_history_entry(entry)
        self.upload_finished.emit(entry)

    def _on_upload_failed(self, message: str) -> None:
        self.upload_action.setEnabled(True)
        self.statusBar().showMessage("Upload failed", 5000)
        QMessageBox.critical(self, "Upload failed", message)
