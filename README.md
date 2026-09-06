# Snapshare

A ShareX-style screenshot / annotate / upload tool for **KDE Plasma on
Wayland** (Arch, Kubuntu, and any other Plasma distro). It captures via
Spectacle (so it works correctly under Wayland), opens a full annotation
editor (arrows, highlighter, shapes, text, step numbers, pixelate/blur,
freehand, crop), and uploads to Imgur anonymously or any custom HTTP
uploader — including a direct import of your existing ShareX `.sxcu`
uploader files.

## Features (parity with ShareX)

| ShareX | Snapshare |
|---|---|
| Region / window / fullscreen / monitor capture | ✅ via `spectacle -b` (Wayland-correct) |
| Annotation editor (arrow, line, rect, ellipse, highlighter, text, step numbers, pixelate, blur, freehand pen, crop) | ✅ |
| Undo / redo | ✅ |
| Upload to Imgur anonymously | ✅ (bring your own free Client-ID) |
| Custom uploaders | ✅, including importing ShareX `.sxcu` JSON files |
| Auto-copy result URL to clipboard | ✅ |
| Upload history browser | ✅ (thumbnails, re-copy URL, open file) |
| System tray quick-capture menu | ✅ |
| Global hotkeys | Bound via KDE's own shortcut system (see below) — Wayland doesn't let ordinary apps grab global hotkeys themselves |
| Scrolling/full-page capture, GIF/video recording | Not in v1 (tracked as future work — see below) |

## Install

### Arch / Manjaro

```sh
sudo pacman -S spectacle python-pyqt6 python-requests
cd packaging && makepkg -si
```

or run straight from source:

```sh
sudo pacman -S spectacle python-pyqt6 python-requests
python -m snapshare tray
```

### Kubuntu / Debian-based

```sh
sudo apt install kde-spectacle python3-pyqt6 python3-requests
pip install --user .
```

## First-run setup

1. Run `snapshare settings` (or Tray icon → Settings…) and add at least one
   uploader:
   - **Imgur (anonymous)**: register a free app at
     https://api.imgur.com/oauth2/addclient (pick "Anonymous usage without
     user authorization"), then paste the generated Client-ID in.
   - **Custom uploader**: click "Import ShareX Custom Uploader (.sxcu)…" and
     point it at any `.sxcu` file you already use in ShareX (catbox, your own
     server, etc.) — the multipart/form-data + JSON-path response format
     that ShareX uses is supported directly.
2. Add `snapshare tray` to Plasma's autostart (System Settings → Autostart →
   Add Application, or copy `packaging/snapshare.desktop` into
   `~/.config/autostart/`) so the tray icon and quick-capture menu are always
   available.
3. Bind capture hotkeys, since Wayland doesn't allow apps to register global
   shortcuts themselves — KDE has to own the binding:
   - System Settings → Shortcuts → Custom Shortcuts → Edit → New → Global
     Shortcut → Command/URL.
   - Set the **Trigger** to e.g. `Print Screen` (or `Meta+Shift+S` for
     region, `Meta+Shift+F` for fullscreen, etc.), and the **Action** command
     to:
     ```
     snapshare capture --mode region
     snapshare capture --mode fullscreen
     snapshare capture --mode active
     snapshare capture --mode monitor
     snapshare capture --mode window
     ```

## Usage

- Click the tray icon (or its default click action) to capture a region.
- Draw on the screenshot with the toolbar tools; pick a color from the
  palette or the color-picker button; adjust stroke width; toggle shape fill.
- **Crop** draws a selection you can clear with "Clear Crop"; it's applied
  only at export time (Save/Copy/Upload), so you can keep annotating outside
  the crop box beforehand.
- **Save**, **Copy** (to clipboard) or **Upload** (also saves a local copy
  and adds an entry to history, and copies the resulting URL to your
  clipboard).
- Tray → "Upload History…" lets you re-copy a URL, reopen the local file, or
  remove old entries.

## Development

```sh
python -m venv .venv && source .venv/bin/activate
pip install -e .
pip install pytest
pytest
python -m snapshare tray
```

## Roadmap

- Scrolling/full-page window capture (no reliable general Wayland API for
  this yet; would be a best-effort, app-specific implementation).
- GIF/video capture via `wf-recorder` or the `ScreenCast` portal.
