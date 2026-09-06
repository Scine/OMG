import importlib

import pytest


@pytest.fixture
def isolated_config(tmp_path, monkeypatch):
    monkeypatch.setenv("XDG_CONFIG_HOME", str(tmp_path / "config"))
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path / "data"))
    monkeypatch.setenv("HOME", str(tmp_path / "home"))

    import snapshare.config as config_module

    importlib.reload(config_module)
    yield config_module
    importlib.reload(config_module)


def test_add_and_list_history_entries(isolated_config):
    from snapshare.history import store

    config = isolated_config.get_config()
    assert store.list_entries() == []

    config.add_history_entry({"timestamp": "t1", "url": "https://example.com/1.png"})
    config.add_history_entry({"timestamp": "t2", "url": "https://example.com/2.png"})

    entries = store.list_entries()
    assert len(entries) == 2
    # Most recent entry first.
    assert entries[0]["url"] == "https://example.com/2.png"


def test_remove_entry(isolated_config):
    from snapshare.history import store

    config = isolated_config.get_config()
    config.add_history_entry({"timestamp": "t1", "url": "https://example.com/1.png"})
    config.add_history_entry({"timestamp": "t2", "url": "https://example.com/2.png"})

    store.remove_entry(0)  # removes the most recent (t2)
    entries = store.list_entries()
    assert len(entries) == 1
    assert entries[0]["url"] == "https://example.com/1.png"


def test_clear_all(isolated_config):
    from snapshare.history import store

    config = isolated_config.get_config()
    config.add_history_entry({"timestamp": "t1", "url": "https://example.com/1.png"})

    store.clear_all()
    assert store.list_entries() == []


def test_active_uploader_defaults_to_imgur(isolated_config):
    config = isolated_config.get_config()
    uploader = config.active_uploader()
    assert uploader is not None
    assert uploader["type"] == "imgur"


def test_add_and_remove_custom_uploader(isolated_config):
    config = isolated_config.get_config()
    config.add_uploader({"type": "custom", "name": "Test", "request_url": "https://x"})
    assert any(u["name"] == "Test" for u in config.uploaders)

    uploader_id = next(u["id"] for u in config.uploaders if u["name"] == "Test")
    config.remove_uploader(uploader_id)
    assert not any(u["name"] == "Test" for u in config.uploaders)
