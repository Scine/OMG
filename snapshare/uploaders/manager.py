"""Dispatches an upload to the correct backend based on uploader config type."""
from __future__ import annotations

from snapshare.uploaders import custom as custom_uploader
from snapshare.uploaders import imgur as imgur_uploader
from snapshare.uploaders.base import UploadError, UploadResult

__all__ = ["UploadError", "UploadResult", "upload_with_config"]


def upload_with_config(config: dict, image_bytes: bytes) -> UploadResult:
    uploader_type = config.get("type")
    if uploader_type == "imgur":
        return imgur_uploader.upload(image_bytes, config.get("client_id", ""))
    if uploader_type == "custom":
        return custom_uploader.upload(image_bytes, config)
    raise UploadError(f"Unknown uploader type: {uploader_type!r}")
