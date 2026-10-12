import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "../code/fetch.js" as Fetch

PlasmoidItem {
    id: root

    // ---- shared state, refreshed on a timer and on expand ----
    property var weatherData: null
    property string weatherError: ""
    property bool weatherLoading: false

    property var stocksData: []
    property string stocksError: ""
    property bool stocksLoading: false

    property var newsData: []
    property string newsError: ""
    property bool newsLoading: false

    property date lastUpdated: new Date(0)

    // Leave preferredRepresentation unset so Plasma picks the compact icon in a
    // panel and the full board on the desktop automatically.
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    function refreshAll() {
        refreshWeather();
        refreshStocks();
        refreshNews();
    }

    function refreshWeather() {
        weatherLoading = true;
        weatherError = "";
        Fetch.fetchWeather(Plasmoid.configuration.latitude,
                           Plasmoid.configuration.longitude,
                           Plasmoid.configuration.temperatureUnit,
                           Plasmoid.configuration.windSpeedUnit,
                           function (err, data) {
            weatherLoading = false;
            if (err) { weatherError = err; return; }
            weatherData = data;
            lastUpdated = new Date();
        });
    }

    function refreshStocks() {
        stocksLoading = true;
        stocksError = "";
        Fetch.fetchStocks(Plasmoid.configuration.stockSymbols, function (err, data) {
            stocksLoading = false;
            if (err) { stocksError = err; return; }
            stocksData = data;
            lastUpdated = new Date();
        });
    }

    function refreshNews() {
        newsLoading = true;
        newsError = "";
        Fetch.fetchNews(Plasmoid.configuration.newsFeedUrl, function (err, data) {
            newsLoading = false;
            if (err) { newsError = err; return; }
            newsData = data;
            lastUpdated = new Date();
        });
    }

    Component.onCompleted: refreshAll()

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    // Refresh when the board is opened if data looks stale (> 5 min).
    onExpandedChanged: {
        if (expanded) {
            var age = (new Date()).getTime() - lastUpdated.getTime();
            if (age > 5 * 60 * 1000) refreshAll();
        }
    }

    toolTipMainText: i18n("Widgets Board")
    toolTipSubText: weatherData
        ? (weatherData.temperature + weatherData.tempSymbol + "  " + weatherData.condition)
        : i18n("News, stocks & weather")

    // ---- panel icon (Windows 11-style corner button) ----
    compactRepresentation: MouseArea {
        id: compactRoot
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.weatherData ? root.weatherData.icon : "view-calendar-day"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            Text {
                visible: root.weatherData !== null
                text: root.weatherData ? (root.weatherData.temperature + root.weatherData.tempSymbol) : ""
                color: Kirigami.Theme.textColor
                font: Kirigami.Theme.defaultFont
            }
        }
    }

    // ---- the board itself ----
    fullRepresentation: Board {}
}
