# Widgets Board — a Windows 11-style widgets panel for KDE Plasma 6

A panel applet (plasmoid) that sits in your taskbar. Click its icon and a board
opens with a **rich weather** view, your **stock watchlist**, and the latest
**news** — the same idea as the Windows 11 "Widgets" button, built for KDE.

Everything is configured through a **graphical settings page** — search for
cities, add/remove stocks with buttons, pick a news source from a list. There
are no config files to edit. It's meant to be installed and used by anyone.

## What it shows

**Weather** (the centerpiece), with three tabs:
- **Details** — large current temperature with a weather glyph and High/Low, then
  a grid of conditions: humidity, pressure, wind (with a direction arrow), dew
  point, visibility, precipitation, UV index, air quality, pollen, space weather
  (Kp index), snowfall and local time — plus a **sunrise/sunset arc** and a
  **moon-phase** panel, and any active weather alerts.
- **Forecast** — a 7-day outlook with highs, lows and precipitation.
- **Radar** — a 7-day precipitation outlook and a button to open a live radar map.

**Markets** — your watchlist with price and daily change (green/red).

**News** — headlines from a source you choose; click one to open it.

Multiple saved weather locations are supported — switch between them with the
arrows in the weather header.

## Data sources (no API keys, nothing to sign up for)

| Data            | Source                                                   |
|-----------------|----------------------------------------------------------|
| Weather, air quality, city search | [Open-Meteo](https://open-meteo.com/) |
| Weather alerts (US) | [NOAA / National Weather Service](https://www.weather.gov/) |
| Space weather (Kp)  | [NOAA SWPC](https://www.swpc.noaa.gov/)              |
| Stocks          | [Stooq](https://stooq.com/) CSV quotes                   |
| News            | Any RSS/Atom feed                                        |

It works out of the box because every source is a free, keyless public endpoint.

## Requirements

- KDE Plasma **6**
- Network access from your session

## Install — the easy way

**Option A — double-click.** Build the package once and open it:

```bash
./build-plasmoid.sh      # creates WidgetsBoard.plasmoid
```

Double-click `WidgetsBoard.plasmoid` in your file manager → KDE offers to
install it. Or run `kpackagetool6 --type Plasma/Applet --install WidgetsBoard.plasmoid`.

**Option B — install script.** From this folder:

```bash
./install.sh
```

Then add it to your panel: right-click the panel → **Add or Manage Widgets…** →
search **Widgets Board** → drag it on. For the Windows 11 look, drop it in the
far corner.

**Option C — preview without installing** (if `plasmoidviewer` is available):

```bash
plasmoidviewer -a ./package
```

### Sharing it with others / the KDE Store

To let anyone install it straight from KDE's **Add Widgets → Get New Widgets…**
browser, upload `WidgetsBoard.plasmoid` to [store.kde.org](https://store.kde.org/)
as a "Plasma 6 Add-On → Plasma Widget". After that, no terminal is needed at all —
users find it by name in the widget browser and click Install.

## Settings (all graphical)

Right-click the widget → **Configure Widgets Board…**:

- **Weather locations** — type a city, click Search, pick a result, click Add.
  Reorder with the up/down buttons, set the default with the radio button,
  remove with the trash button.
- **Units** — Fahrenheit/Celsius and mph/km-h.
- **Stock watchlist** — type a symbol, click Add; remove with the ✕ on each chip.
- **News feed** — choose a source from the dropdown, or pick Custom and paste any
  feed URL.
- **Updates** — refresh interval (5–240 minutes).

## Uninstall

```bash
kpackagetool6 --type Plasma/Applet --remove org.kde.widgetsboard
```

## Project layout

```
package/
  metadata.json                 applet manifest
  contents/
    config/  main.xml, config.qml      settings schema + categories
    ui/
      main.qml                  root: panel icon, board, data fetching, locations
      Board.qml                 the pop-open board
      WeatherCard.qml           tabbed weather (Details/Forecast/Radar)
      WeatherGlyph.qml          canvas-drawn sun/moon/cloud graphic
      SunArc.qml                sunrise/sunset arc panel
      MoonPanel.qml             moon-phase panel
      DetailTile.qml            one metric row
      SegmentedControl.qml      the tab switcher
      StocksCard.qml / NewsCard.qml / Card.qml
      configGeneral.qml         graphical settings page
    code/
      fetch.js                  HTTP + all data parsing (weather, air, alerts,
                                space weather, stocks, RSS, geocoding, locations)
build-plasmoid.sh               builds the installable .plasmoid
install.sh                      install/upgrade helper
```

## Notes & limitations

- Weather **alerts** and some metrics (US AQI, pollen coverage) are strongest in
  the United States; elsewhere those tiles may read `--` when a source has no data.
- Stock "change" is computed against the day's opening price from Stooq and can be
  delayed — fine for glancing, not for trading.
- The moon panel shows the astronomically-correct phase and illumination; it's a
  visual summary, not a precise moonrise/moonset timetable.
- The RSS parser is intentionally dependency-free (regex-based); very unusual
  feeds may render a little rough.
