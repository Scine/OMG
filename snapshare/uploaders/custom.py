"""Generic HTTP custom uploader, compatible with a practical subset of
ShareX's ".sxcu" custom uploader format so existing ShareX configs
(imgur mirrors, catbox, personal servers, etc.) can be reused as-is.
"""
from __future__ import annotations

import json
import re
from typing import Any

import requests

from snapshare.uploaders.base import UploadError, UploadResult

_JSON_SPEC = re.compile(r"^\$json:(?P<path>[^$]+)\$$")
_REGEX_SPEC = re.compile(r"^\$regex:(?P<pattern>.+)\$$")


def _dig(data: Any, path: str) -> Any:
    """Resolve a dotted/bracketed JSON path like 'data.link' or 'files[0].url'."""
    current = data
    for part in re.split(r"\.", path):
        m = re.match(r"^([^\[\]]*)((\[\d+\])*)$", part)
        key, indices = m.group(1), m.group(2)
        if key:
            if not isinstance(current, dict) or key not in current:
                raise UploadError(f"Response JSON has no field '{key}' (looking for '{path}')")
            current = current[key]
        for idx_match in re.finditer(r"\[(\d+)\]", indices):
            idx = int(idx_match.group(1))
            current = current[idx]
    return current


def extract_value(spec: str, response_text: str) -> str:
    """Resolve a ShareX-style response spec against the raw response body."""
    if not spec:
        return response_text.strip()

    json_match = _JSON_SPEC.match(spec.strip())
    if json_match:
        try:
            data = json.loads(response_text)
        except ValueError as exc:
            raise UploadError("Uploader response was not valid JSON") from exc
        value = _dig(data, json_match.group("path"))
        return str(value)

    regex_match = _REGEX_SPEC.match(spec.strip())
    if regex_match:
        m = re.search(regex_match.group("pattern"), response_text)
        if not m:
            raise UploadError("Uploader response did not match the configured regex")
        return m.group(1) if m.groups() else m.group(0)

    # A literal template like "https://example.com/{response}"
    return spec.replace("{response}", response_text.strip())


def upload(image_bytes: bytes, config: dict) -> UploadResult:
    request_url = config.get("request_url")
    if not request_url:
        raise UploadError("Custom uploader has no Request URL configured.")

    method = config.get("method", "POST").upper()
    file_form_name = config.get("file_form_name", "file")
    headers = config.get("headers", {}) or {}
    arguments = config.get("arguments", {}) or {}
    filename = config.get("upload_filename", "snapshare.png")

    files = {file_form_name: (filename, image_bytes, "image/png")}

    try:
        response = requests.request(
            method,
            request_url,
            headers=headers,
            data=arguments,
            files=files,
            timeout=60,
        )
    except requests.RequestException as exc:
        raise UploadError(f"Network error talking to custom uploader: {exc}") from exc

    if not response.ok:
        raise UploadError(f"Custom uploader returned HTTP {response.status_code}: {response.text[:300]}")

    url = extract_value(config.get("url_spec", ""), response.text)
    delete_url = None
    if config.get("deletion_url_spec"):
        try:
            delete_url = extract_value(config["deletion_url_spec"], response.text)
        except UploadError:
            delete_url = None

    return UploadResult(url=url, delete_url=delete_url, raw_response=response.text)


def parse_sxcu(raw: dict) -> dict:
    """Normalize a parsed ShareX .sxcu JSON document into our uploader config
    shape. Only the ImageUploader / multipart-form-data subset is supported,
    which covers the overwhelming majority of real-world custom uploaders.
    """
    if raw.get("Body") not in (None, "MultipartFormData"):
        raise UploadError(
            f"Unsupported ShareX uploader Body type '{raw.get('Body')}'. "
            "Only MultipartFormData custom uploaders are supported."
        )

    return {
        "type": "custom",
        "name": raw.get("Name", "Imported ShareX uploader"),
        "request_url": raw.get("RequestURL", ""),
        "method": raw.get("RequestMethod", "POST"),
        "file_form_name": raw.get("FileFormName", "file"),
        "headers": raw.get("Headers", {}) or {},
        "arguments": raw.get("Arguments", {}) or {},
        "url_spec": raw.get("URL", ""),
        "deletion_url_spec": raw.get("DeletionURL", ""),
    }
