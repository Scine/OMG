"""Anonymous image upload to Imgur.

Imgur's anonymous upload API still requires a Client-ID (no OAuth/login),
obtained for free by registering an "Application" at
https://api.imgur.com/oauth2/addclient (choose "Anonymous usage without
user authorization"). This mirrors exactly what ShareX's built-in Imgur
uploader does.
"""
from __future__ import annotations

import base64

import requests

from snapshare.uploaders.base import UploadError, UploadResult

IMGUR_UPLOAD_URL = "https://api.imgur.com/3/image"
IMGUR_DELETE_BASE = "https://imgur.com/delete/"


def upload(image_bytes: bytes, client_id: str) -> UploadResult:
    if not client_id:
        raise UploadError(
            "No Imgur Client-ID configured. Register a free application at "
            "https://api.imgur.com/oauth2/addclient and paste the Client-ID "
            "into Snapshare's uploader settings."
        )

    try:
        response = requests.post(
            IMGUR_UPLOAD_URL,
            headers={"Authorization": f"Client-ID {client_id}"},
            data={"image": base64.b64encode(image_bytes), "type": "base64"},
            timeout=30,
        )
    except requests.RequestException as exc:
        raise UploadError(f"Network error talking to Imgur: {exc}") from exc

    try:
        payload = response.json()
    except ValueError as exc:
        raise UploadError(f"Imgur returned a non-JSON response (HTTP {response.status_code})") from exc

    if not response.ok or not payload.get("success"):
        message = payload.get("data", {}).get("error", response.text)
        raise UploadError(f"Imgur upload failed: {message}")

    data = payload["data"]
    return UploadResult(
        url=data["link"],
        delete_url=IMGUR_DELETE_BASE + data["deletehash"] if data.get("deletehash") else None,
        raw_response=response.text,
    )
