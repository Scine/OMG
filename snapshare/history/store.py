"""Thin accessor over the upload history persisted in Config.

Each entry: {"timestamp": iso8601, "file_path": str, "url": str,
"delete_url": str | None}.
"""
from __future__ import annotations

from typing import Any

from snapshare.config import get_config


def list_entries() -> list[dict[str, Any]]:
    return get_config().get("history", [])


def remove_entry(index: int) -> None:
    config = get_config()
    history = config.get("history", [])
    if 0 <= index < len(history):
        del history[index]
        config.save()


def clear_all() -> None:
    config = get_config()
    config.set("history", [])
