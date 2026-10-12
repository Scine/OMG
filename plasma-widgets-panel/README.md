# Widgets Board — a Windows 11-style widgets panel for KDE Plasma 6

A panel applet (plasmoid) that sits in your taskbar. Click its icon and a board
slides open with **weather**, **stocks/markets**, and **news** — the same idea as
the Windows 11 "Widgets" button in the corner of the taskbar.

![layout](docs/preview.txt)

## What it shows

- **Weather** — current conditions plus a 5-day forecast, for any city.
- **Markets** — a watchlist of stock symbols with price and daily change.
- **News** — the latest headlines from any RSS/Atom feed; click one to open it.

Everything refreshes on a timer (configurable) and when you open the board.

## Data sources (no API keys required)

| Widget  | Source       | Notes                                              |
|---------|--------------|----------------------------------------------------|
| Weather | [Open-Meteo](https://open-meteo.com/) | Free, no key. Also used for city search. |
| Stocks  | [Stooq](https://stooq.com/)           | Free CSV quotes. May be delayed; change is vs. today's open. |
| News    | Any RSS/Atom feed | Defaults to Google News top stories.           |

Because it uses only keyless public endpoints, it works out of the box. You can
point the news feed at anything you like.

## Requirements

- KDE Plasma **6** (Plasma 5 is not supported — the QML uses Plasma 6 imports).
- Network access from your session.

## Install

```bash
./install.sh
```

Then right-click your panel → **Add or Manage Widgets…**, search for
**Widgets Board**, and drag it onto the panel. For the Windows 11 feel, drop it
in the far corner of the panel.

To preview without installing (if `plasmoidviewer` is available):

```bash
plasmoidviewer -a ./package
```

## Configure

Right-click the widget → **Configure Widgets Board…**:

- **Location** — type a city, hit *Search*, pick a result; it fills in the
  coordinates for you. Or enter latitude/longitude by hand.
- **Units** — Fahrenheit/Celsius and mph/km-h.
- **Markets** — comma-separated symbols. US tickers like `AAPL` work as-is; use
  `^SPX`, `^DJI` for indices, or an exchange suffix such as `VOD.UK`.
- **News** — any RSS or Atom feed URL.
- **Updates** — how often to refresh (5–240 minutes).

## Uninstall

```bash
kpackagetool6 --type Plasma/Applet --remove org.kde.widgetsboard
```

## Project layout

```
package/
  metadata.json                 applet manifest
  contents/
    config/
      main.xml                  settings schema + defaults
      config.qml                settings categories
    ui/
      main.qml                  root: panel icon + board, data fetching
      Board.qml                 the pop-open board layout
      Card.qml                  reusable rounded card frame
      WeatherCard.qml           current conditions + 5-day forecast
      StocksCard.qml            watchlist
      NewsCard.qml              headlines
      configGeneral.qml         settings page (with city search)
    code/
      fetch.js                  HTTP + Open-Meteo / Stooq / RSS parsing
install.sh                      install/upgrade helper
```

## Notes & limitations

- Stock "change" is computed against the day's opening price from Stooq's quote
  CSV, which can lag real time. For anything you trade on, use a brokerage app.
- The RSS parser is deliberately lightweight (regex-based) so it has no
  dependencies; extremely unusual feeds may render a little rough.
