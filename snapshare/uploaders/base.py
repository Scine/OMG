"""Shared types for the pluggable uploader backends."""
from __future__ import annotations

from dataclasses import dataclass


class UploadError(RuntimeError):
    pass


@dataclass
class UploadResult:
    url: str
    delete_url: str | None = None
    raw_response: str | None = None
