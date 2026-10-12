import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "../code/fetch.js" as Fetch

PlasmoidItem {
    id: root

    // ---- weather ----
    property var weatherData: null
    property string weatherError: ""
    property bool weatherLoading: false
    property var airData: null
    property var alertsData: []
    property var spaceData: null

    // ---- stocks ----
    property var stocksData: []
    property string stocksError: ""
    property bool stocksLoading: false

    // ---- news ----
    property var newsData: []
    property string newsError: ""
    property bool newsLoading: false

    property date lastUpdated: new Date(0)

    // ---- locations ----
    property var locations: []
    property int activeLocation: 0

    Plasmoid.constraintHints: Plasmoid.CanFillArea

    function loadLocations() {
        var list = Fetch.parseLocations(Plasmoid.configuration.savedLocations);
        // Make sure the active lat/lon is represented.
        if (list.length === 0) {
            list = [{
                name: Plasmoid.configuration.locationName,
                latitude: Plasmoid.configuration.latitude,
                longitude: Plasmoid.configuration.longitude
            }];
        }
        locations = list;
        // Find the entry matching the stored active coordinates.
        var found = 0;
        for (var i = 0; i < list.length; i++) {
            if (Math.abs(list[i].latitude - Plasmoid.configuration.latitude) < 0.001
                && Math.abs(list[i].longitude - Plasmoid.configuration.longitude) < 0.001) {
                found = i; break;
            }
        }
        activeLocation = found;
    }

    function setActiveLocation(index) {
        if (index < 0 || index >= locations.length) return;
        activeLocation = index;
        var loc = locations[index];
        Plasmoid.configuration.locationName = loc.name;
        Plasmoid.configuration.latitude = loc.latitude;
        Plasmoid.configuration.longitude = loc.longitude;
        Plasmoid.configuration.writeConfig();
        refreshWeather();
    }

    function cycleLocation(delta) {
        if (locations.length < 2) return;
        var n = (activeLocation + delta + locations.length) % locations.length;
        setActiveLocation(n);
    }

    function refreshAll() {
        refreshWeather();
        refreshStocks();
        refreshNews();
    }

    function refreshWeather() {
        weatherLoading = true;
        weatherError = "";
        var lat = Plasmoid.configuration.latitude;
        var lon = Plasmoid.configuration.longitude;

        Fetch.fetchWeather(lat, lon,
                           Plasmoid.configuration.temperatureUnit,
                           Plasmoid.configuration.windSpeedUnit,
                           function (err, data) {
            weatherLoading = false;
            if (err) { weatherError = err; return; }
            weatherData = data;
            lastUpdated = new Date();
        });

        Fetch.fetchAirQuality(lat, lon, function (err, data) { airData = data; });
        Fetch.fetchAlerts(lat, lon, function (err, data) { alertsData = data || []; });
        Fetch.fetchSpaceWeather(function (err, data) { spaceData = data; });
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

    Component.onCompleted: {
        loadLocations();
        refreshAll();
    }

    // Reload the location list and refresh when settings are applied.
    Connections {
        target: Plasmoid.configuration
        function onSavedLocationsChanged() { root.loadLocations(); }
        function onLatitudeChanged() { root.loadLocations(); root.refreshWeather(); }
        function onStockSymbolsChanged() { root.refreshStocks(); }
        function onNewsFeedUrlChanged() { root.refreshNews(); }
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

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

    fullRepresentation: Board { applet: root }
}
