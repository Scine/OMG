"""Upload history viewer: thumbnails, quick re-copy of URLs, cleanup."""
from __future__ import annotations

import subprocess
from pathlib import Path

from PyQt6.QtCore import QSize, Qt
from PyQt6.QtGui import QIcon, QPixmap
from PyQt6.QtWidgets import (
    QAbstractItemView,
    QApplication,
    QHBoxLayout,
    QListWidget,
    QListWidgetItem,
    QMenu,
    QMessageBox,
    QPushButton,
    QVBoxLayout,
    QWidget,
)

from snapshare.history import store


class HistoryWindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Snapshare — Upload History")
        self.resize(720, 480)

        self.list_widget = QListWidget()
        self.list_widget.setViewMode(QListWidget.ViewMode.IconMode)
        self.list_widget.setIconSize(QSize(128, 96))
        self.list_widget.setResizeMode(QListWidget.ResizeMode.Adjust)
        self.list_widget.setSpacing(8)
        self.list_widget.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.list_widget.itemDoubleClicked.connect(self._copy_url)
        self.list_widget.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.list_widget.customContextMenuRequested.connect(self._show_context_menu)

        layout = QVBoxLayout(self)
        layout.addWidget(self.list_widget)

        buttons = QHBoxLayout()
        copy_btn = QPushButton("Copy URL")
        copy_btn.clicked.connect(lambda: self._copy_url(self.list_widget.currentItem()))
        open_btn = QPushButton("Open File")
        open_btn.clicked.connect(lambda: self._open_file(self.list_widget.currentItem()))
        remove_btn = QPushButton("Remove")
        remove_btn.clicked.connect(self._remove_selected)
        clear_btn = QPushButton("Clear All")
        clear_btn.clicked.connect(self._clear_all)
        for b in (copy_btn, open_btn, remove_btn, clear_btn):
            buttons.addWidget(b)
        layout.addLayout(buttons)

        self.refresh()

    def refresh(self) -> None:
        self.list_widget.clear()
        for index, entry in enumerate(store.list_entries()):
            label = f"{entry.get('timestamp', '')}\n{entry.get('url', '(no url)')}"
            item = QListWidgetItem(label)
            item.setData(Qt.ItemDataRole.UserRole, index)
            path = entry.get("file_path")
            if path and Path(path).exists():
                pixmap = QPixmap(path).scaled(
                    128, 96, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation
                )
                item.setIcon(QIcon(pixmap))
            self.list_widget.addItem(item)

    def _entry_for(self, item: QListWidgetItem | None) -> dict | None:
        if item is None:
            return None
        entries = store.list_entries()
        index = item.data(Qt.ItemDataRole.UserRole)
        if index is None or index >= len(entries):
            return None
        return entries[index]

    def _copy_url(self, item: QListWidgetItem | None) -> None:
        entry = self._entry_for(item)
        if entry and entry.get("url"):
            QApplication.clipboard().setText(entry["url"])

    def _open_file(self, item: QListWidgetItem | None) -> None:
        entry = self._entry_for(item)
        if entry and entry.get("file_path"):
            subprocess.Popen(["xdg-open", entry["file_path"]])

    def _remove_selected(self) -> None:
        item = self.list_widget.currentItem()
        if item is None:
            return
        index = item.data(Qt.ItemDataRole.UserRole)
        store.remove_entry(index)
        self.refresh()

    def _clear_all(self) -> None:
        if QMessageBox.question(self, "Clear history", "Remove all history entries?") == QMessageBox.StandardButton.Yes:
            store.clear_all()
            self.refresh()

    def _show_context_menu(self, pos) -> None:
        item = self.list_widget.itemAt(pos)
        if item is None:
            return
        menu = QMenu(self)
        menu.addAction("Copy URL", lambda: self._copy_url(item))
        menu.addAction("Open File", lambda: self._open_file(item))
        menu.addAction("Remove", lambda: (store.remove_entry(item.data(Qt.ItemDataRole.UserRole)), self.refresh()))
        menu.exec(self.list_widget.mapToGlobal(pos))
