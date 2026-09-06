import json

import pytest

from snapshare.uploaders.base import UploadError
from snapshare.uploaders.custom import extract_value, parse_sxcu


def test_extract_value_json_path():
    response = json.dumps({"data": {"link": "https://example.com/x.png", "deletehash": "abc"}})
    assert extract_value("$json:data.link$", response) == "https://example.com/x.png"
    assert extract_value("$json:data.deletehash$", response) == "abc"


def test_extract_value_json_path_with_array_index():
    response = json.dumps({"files": [{"url": "https://example.com/a.png"}]})
    assert extract_value("$json:files[0].url$", response) == "https://example.com/a.png"


def test_extract_value_json_missing_field_raises():
    response = json.dumps({"data": {}})
    with pytest.raises(UploadError):
        extract_value("$json:data.link$", response)


def test_extract_value_regex():
    response = "upload ok: https://example.com/foo.png done"
    assert extract_value(r"$regex:(https://\S+\.png)$", response) == "https://example.com/foo.png"


def test_extract_value_literal_template():
    assert extract_value("https://cdn.example.com/{response}", "abc123") == "https://cdn.example.com/abc123"


def test_extract_value_empty_spec_returns_raw_response():
    assert extract_value("", "  raw-url  ") == "raw-url"


def test_parse_sxcu_normalizes_fields():
    raw = {
        "Name": "My Uploader",
        "RequestURL": "https://example.com/upload",
        "RequestMethod": "POST",
        "Body": "MultipartFormData",
        "FileFormName": "file",
        "Headers": {"Authorization": "Bearer xyz"},
        "Arguments": {"key": "value"},
        "URL": "$json:data.link$",
        "DeletionURL": "$json:data.deletehash$",
    }
    config = parse_sxcu(raw)
    assert config["type"] == "custom"
    assert config["name"] == "My Uploader"
    assert config["request_url"] == "https://example.com/upload"
    assert config["file_form_name"] == "file"
    assert config["headers"] == {"Authorization": "Bearer xyz"}
    assert config["url_spec"] == "$json:data.link$"


def test_parse_sxcu_rejects_unsupported_body():
    raw = {"Name": "Weird", "RequestURL": "https://x", "Body": "JSON"}
    with pytest.raises(UploadError):
        parse_sxcu(raw)
