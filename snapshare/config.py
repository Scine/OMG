"""Persistent application settings stored as JSON under XDG_CONFIG_HOME."""
from __future__ import annotations

import json
import os
import uuid
from pathlib import Path
from typing import Any

APP_NAME = "snapshare"


def config_dir() -> Path:
    base = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    d = Path(base) / APP_NAME
    d.mkdir(parents=True, exist_ok=True)
    return d


def data_dir() -> Path:
    base = os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share"))
    d = Path(base) / APP_NAME
    d.mkdir(parents=True, exist_ok=True)
    return d


def captures_dir() -> Path:
    d = data_dir() / "captures"
    d.mkdir(parents=True, exist_ok=True)
    return d


DEFAULTS: dict[str, Any] = {
    "save_directory": str(Path.home() / "Pictures" / "Screenshots"),
    "copy_url_to_clipboard": True,
    "copy_image_to_clipboard_on_close": False,
    "auto_upload": True,
    "open_editor_before_upload": True,
    "active_uploader_id": "imgur-anonymous",
    "uploaders": [
        {
            "id": "imgur-anonymous",
            "type": "imgur",
            "name": "Imgur (anonymous)",
            "client_id": "",
        }
    ],
    "history": [],
}


class Config:
    def __init__(self) -> None:
        self._path = config_dir() / "config.json"
        self._data: dict[str, Any] = json.loads(json.dumps(DEFAULTS))
        self.load()

    def load(self) -> None:
        if self._path.exists():
            try:
                on_disk = json.loads(self._path.read_text())
                self._data.update(on_disk)
            except (json.JSONDecodeError, OSError):
                pass
        Path(self._data["save_directory"]).mkdir(parents=True, exist_ok=True)

    def save(self) -> None:
        self._path.write_text(json.dumps(self._data, indent=2))

    def get(self, key: str, default: Any = None) -> Any:
        return self._data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        self._data[key] = value
        self.save()

    @property
    def uploaders(self) -> list[dict[str, Any]]:
        return self._data.setdefault("uploaders", [])

    def add_uploader(self, uploader: dict[str, Any]) -> None:
        uploader.setdefault("id", str(uuid.uuid4()))
        self.uploaders.append(uploader)
        self.save()

    def remove_uploader(self, uploader_id: str) -> None:
        self._data["uploaders"] = [u for u in self.uploaders if u["id"] != uploader_id]
        self.save()

    def active_uploader(self) -> dict[str, Any] | None:
        active_id = self.get("active_uploader_id")
        for u in self.uploaders:
            if u["id"] == active_id:
                return u
        return self.uploaders[0] if self.uploaders else None

    def add_history_entry(self, entry: dict[str, Any]) -> None:
        history = self._data.setdefault("history", [])
        history.insert(0, entry)
        del history[500:]
        self.save()


_instance: Config | None = None


def get_config() -> Config:
    global _instance
    if _instance is None:
        _instance = Config()
    return _instance
