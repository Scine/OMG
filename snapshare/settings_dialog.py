"""Settings dialog: general behavior + uploader management."""
from __future__ import annotations

import json

from PyQt6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QDialog,
    QFileDialog,
    QFormLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMessageBox,
    QPushButton,
    QTabWidget,
    QVBoxLayout,
    QWidget,
)

from snapshare.config import get_config
from snapshare.uploaders.custom import parse_sxcu
from snapshare.uploaders.base import UploadError


class GeneralTab(QWidget):
    def __init__(self, config) -> None:
        super().__init__()
        self.config = config
        layout = QFormLayout(self)

        self.save_dir_edit = QLineEdit(config.get("save_directory"))
        browse_btn = QPushButton("Browse…")
        browse_btn.clicked.connect(self._browse)
        dir_row = QHBoxLayout()
        dir_row.addWidget(self.save_dir_edit)
        dir_row.addWidget(browse_btn)
        dir_widget = QWidget()
        dir_widget.setLayout(dir_row)
        layout.addRow("Save directory", dir_widget)

        self.copy_url_check = QCheckBox("Copy uploaded URL to clipboard")
        self.copy_url_check.setChecked(config.get("copy_url_to_clipboard", True))
        layout.addRow(self.copy_url_check)

        self.auto_upload_check = QCheckBox("Automatically upload after editing (Upload button still required per-shot)")
        self.auto_upload_check.setChecked(config.get("auto_upload", True))
        layout.addRow(self.auto_upload_check)

        self.open_editor_check = QCheckBox("Open editor before uploading")
        self.open_editor_check.setChecked(config.get("open_editor_before_upload", True))
        layout.addRow(self.open_editor_check)

    def _browse(self) -> None:
        directory = QFileDialog.getExistingDirectory(self, "Choose save directory", self.save_dir_edit.text())
        if directory:
            self.save_dir_edit.setText(directory)

    def save(self) -> None:
        self.config.set("save_directory", self.save_dir_edit.text())
        self.config.set("copy_url_to_clipboard", self.copy_url_check.isChecked())
        self.config.set("auto_upload", self.auto_upload_check.isChecked())
        self.config.set("open_editor_before_upload", self.open_editor_check.isChecked())


class UploadersTab(QWidget):
    def __init__(self, config) -> None:
        super().__init__()
        self.config = config

        layout = QVBoxLayout(self)
        self.list_widget = QListWidget()
        layout.addWidget(self.list_widget)
        self._reload_list()

        active_row = QHBoxLayout()
        active_row.addWidget(QLabel("Active uploader:"))
        self.active_combo = QComboBox()
        active_row.addWidget(self.active_combo)
        layout.addLayout(active_row)
        self._reload_combo()

        # -- Imgur quick setup ------------------------------------------------
        imgur_form = QFormLayout()
        self.imgur_client_id_edit = QLineEdit()
        imgur_default = next((u for u in config.uploaders if u["type"] == "imgur"), None)
        if imgur_default:
            self.imgur_client_id_edit.setText(imgur_default.get("client_id", ""))
        imgur_form.addRow("Imgur Client-ID", self.imgur_client_id_edit)
        save_imgur_btn = QPushButton("Save Imgur Client-ID")
        save_imgur_btn.clicked.connect(self._save_imgur_client_id)
        imgur_form.addRow(save_imgur_btn)
        layout.addLayout(imgur_form)

        # -- Custom uploader import ------------------------------------------
        import_btn = QPushButton("Import ShareX Custom Uploader (.sxcu)…")
        import_btn.clicked.connect(self._import_sxcu)
        layout.addWidget(import_btn)

        remove_btn = QPushButton("Remove selected uploader")
        remove_btn.clicked.connect(self._remove_selected)
        layout.addWidget(remove_btn)

    def _reload_list(self) -> None:
        self.list_widget.clear()
        for uploader in self.config.uploaders:
            self.list_widget.addItem(QListWidgetItem(f"{uploader['name']}  [{uploader['type']}]"))

    def _reload_combo(self) -> None:
        self.active_combo.clear()
        active_id = self.config.get("active_uploader_id")
        active_index = 0
        for i, uploader in enumerate(self.config.uploaders):
            self.active_combo.addItem(uploader["name"], uploader["id"])
            if uploader["id"] == active_id:
                active_index = i
        self.active_combo.setCurrentIndex(active_index)

    def _save_imgur_client_id(self) -> None:
        client_id = self.imgur_client_id_edit.text().strip()
        imgur_cfg = next((u for u in self.config.uploaders if u["type"] == "imgur"), None)
        if imgur_cfg is None:
            self.config.add_uploader({"type": "imgur", "name": "Imgur (anonymous)", "client_id": client_id})
        else:
            imgur_cfg["client_id"] = client_id
            self.config.save()
        self._reload_list()
        self._reload_combo()
        QMessageBox.information(self, "Saved", "Imgur Client-ID saved.")

    def _import_sxcu(self) -> None:
        path, _ = QFileDialog.getOpenFileName(self, "Import ShareX Custom Uploader", "", "ShareX Uploader (*.sxcu *.json)")
        if not path:
            return
        try:
            with open(path, "r", encoding="utf-8") as fh:
                raw = json.load(fh)
            normalized = parse_sxcu(raw)
        except (json.JSONDecodeError, UploadError, OSError) as exc:
            QMessageBox.critical(self, "Import failed", str(exc))
            return

        self.config.add_uploader(normalized)
        self._reload_list()
        self._reload_combo()
        QMessageBox.information(self, "Imported", f"Added uploader '{normalized['name']}'.")

    def _remove_selected(self) -> None:
        row = self.list_widget.currentRow()
        if row < 0:
            return
        uploader = self.config.uploaders[row]
        self.config.remove_uploader(uploader["id"])
        self._reload_list()
        self._reload_combo()

    def save(self) -> None:
        active_id = self.active_combo.currentData()
        if active_id:
            self.config.set("active_uploader_id", active_id)


class SettingsDialog(QDialog):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Snapshare Settings")
        self.resize(560, 480)
        self.config = get_config()

        tabs = QTabWidget()
        self.general_tab = GeneralTab(self.config)
        self.uploaders_tab = UploadersTab(self.config)
        tabs.addTab(self.general_tab, "General")
        tabs.addTab(self.uploaders_tab, "Uploaders")

        buttons = QHBoxLayout()
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self._save_and_close)
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        buttons.addStretch(1)
        buttons.addWidget(save_btn)
        buttons.addWidget(cancel_btn)

        layout = QVBoxLayout(self)
        layout.addWidget(tabs)
        layout.addLayout(buttons)

    def _save_and_close(self) -> None:
        self.general_tab.save()
        self.uploaders_tab.save()
        self.accept()
