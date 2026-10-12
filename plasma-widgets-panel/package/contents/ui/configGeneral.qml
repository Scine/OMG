import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM
import "../code/fetch.js" as Fetch

KCM.SimpleKCM {
    id: page

    // Config values written on save. The list-based ones are serialized
    // strings that the GUI keeps in sync; users never edit them directly.
    property string cfg_locationName: plasmoid.configuration.locationName
    property double cfg_latitude: plasmoid.configuration.latitude
    property double cfg_longitude: plasmoid.configuration.longitude
    property string cfg_savedLocations: plasmoid.configuration.savedLocations
    property string cfg_stockSymbols: plasmoid.configuration.stockSymbols
    property alias cfg_newsFeedUrl: newsUrl.text
    property alias cfg_refreshIntervalMinutes: refreshSpin.value
    property string cfg_temperatureUnit: tempF.checked ? "fahrenheit" : "celsius"
    property string cfg_windSpeedUnit: windMph.checked ? "mph" : "kmh"

    property int activeLocationIndex: 0
    property var searchResults: []

    ListModel { id: locModel }
    ListModel { id: stockModel }

    Component.onCompleted: {
        // locations
        var locs = Fetch.parseLocations(plasmoid.configuration.savedLocations);
        if (locs.length === 0) {
            locs = [{ name: plasmoid.configuration.locationName,
                      latitude: plasmoid.configuration.latitude,
                      longitude: plasmoid.configuration.longitude }];
        }
        for (var i = 0; i < locs.length; i++) {
            locModel.append({ name: locs[i].name, lat: locs[i].latitude, lon: locs[i].longitude });
            if (Math.abs(locs[i].latitude - plasmoid.configuration.latitude) < 0.001
                && Math.abs(locs[i].longitude - plasmoid.configuration.longitude) < 0.001) {
                activeLocationIndex = i;
            }
        }
        // stocks
        var syms = plasmoid.configuration.stockSymbols.split(",");
        for (var j = 0; j < syms.length; j++) {
            var s = syms[j].trim();
            if (s.length > 0) stockModel.append({ symbol: s.toUpperCase() });
        }
        // units
        tempF.checked = (plasmoid.configuration.temperatureUnit === "fahrenheit");
        tempC.checked = !tempF.checked;
        windMph.checked = (plasmoid.configuration.windSpeedUnit === "mph");
        windKmh.checked = !windMph.checked;
    }

    function syncLocations() {
        var arr = [];
        for (var i = 0; i < locModel.count; i++) {
            var r = locModel.get(i);
            arr.push({ name: r.name, latitude: r.lat, longitude: r.lon });
        }
        cfg_savedLocations = Fetch.formatLocations(arr);
        if (activeLocationIndex >= arr.length) activeLocationIndex = 0;
        if (arr.length > 0) {
            var a = arr[activeLocationIndex];
            cfg_locationName = a.name;
            cfg_latitude = a.latitude;
            cfg_longitude = a.longitude;
        }
    }

    function syncStocks() {
        var arr = [];
        for (var i = 0; i < stockModel.count; i++) arr.push(stockModel.get(i).symbol);
        cfg_stockSymbols = arr.join(",");
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.largeSpacing

        // ============ LOCATIONS ============
        Kirigami.Heading { text: i18n("Weather locations"); level: 3 }

        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField {
                id: citySearch
                Layout.fillWidth: true
                placeholderText: i18n("Search for a city to add…")
                onAccepted: searchBtn.clicked()
            }
            QQC2.Button {
                id: searchBtn
                text: i18n("Search")
                icon.name: "search"
                onClicked: {
                    if (citySearch.text.trim().length === 0) return;
                    searchStatus.text = i18n("Searching…");
                    resultsCombo.model = [];
                    page.searchResults = [];
                    Fetch.geocode(citySearch.text, function (err, results) {
                        if (err) { searchStatus.text = i18n("Search failed: %1", err); return; }
                        if (!results || results.length === 0) { searchStatus.text = i18n("No matches."); return; }
                        var labels = [];
                        page.searchResults = results;
                        for (var i = 0; i < results.length; i++) {
                            var r = results[i];
                            var p = [r.name];
                            if (r.admin1) p.push(r.admin1);
                            if (r.country) p.push(r.country);
                            labels.push(p.join(", "));
                        }
                        resultsCombo.model = labels;
                        resultsCombo.currentIndex = 0;
                        searchStatus.text = "";
                    });
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: resultsCombo.count > 0
            QQC2.ComboBox {
                id: resultsCombo
                Layout.fillWidth: true
            }
            QQC2.Button {
                text: i18n("Add")
                icon.name: "list-add"
                enabled: resultsCombo.count > 0
                onClicked: {
                    var r = page.searchResults[resultsCombo.currentIndex];
                    if (!r) return;
                    var nm = r.name + (r.admin1 ? ", " + r.admin1 : "");
                    locModel.append({ name: nm, lat: r.latitude, lon: r.longitude });
                    if (locModel.count === 1) activeLocationIndex = 0;
                    syncLocations();
                    citySearch.text = "";
                    resultsCombo.model = [];
                }
            }
        }
        QQC2.Label {
            id: searchStatus
            visible: text.length > 0
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }

        // saved list
        Repeater {
            model: locModel
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: locRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: index === activeLocationIndex
                       ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                RowLayout {
                    id: locRow
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    QQC2.RadioButton {
                        checked: index === activeLocationIndex
                        text: i18n("Default")
                        onClicked: { activeLocationIndex = index; syncLocations(); }
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.name
                        elide: Text.ElideRight
                    }
                    QQC2.ToolButton {
                        icon.name: "go-up"
                        enabled: index > 0
                        onClicked: { locModel.move(index, index - 1, 1); if (activeLocationIndex === index) activeLocationIndex--; else if (activeLocationIndex === index - 1) activeLocationIndex++; syncLocations(); }
                    }
                    QQC2.ToolButton {
                        icon.name: "go-down"
                        enabled: index < locModel.count - 1
                        onClicked: { locModel.move(index, index + 1, 1); if (activeLocationIndex === index) activeLocationIndex++; else if (activeLocationIndex === index + 1) activeLocationIndex--; syncLocations(); }
                    }
                    QQC2.ToolButton {
                        icon.name: "list-remove"
                        enabled: locModel.count > 1
                        onClicked: {
                            locModel.remove(index);
                            if (activeLocationIndex >= locModel.count) activeLocationIndex = locModel.count - 1;
                            syncLocations();
                        }
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ============ UNITS ============
        Kirigami.Heading { text: i18n("Units"); level: 3 }
        RowLayout {
            QQC2.Label { text: i18n("Temperature:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
            QQC2.RadioButton { id: tempF; text: i18n("Fahrenheit") }
            QQC2.RadioButton { id: tempC; text: i18n("Celsius") }
        }
        RowLayout {
            QQC2.Label { text: i18n("Wind speed:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
            QQC2.RadioButton { id: windMph; text: i18n("mph") }
            QQC2.RadioButton { id: windKmh; text: i18n("km/h") }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ============ STOCKS ============
        Kirigami.Heading { text: i18n("Stock watchlist"); level: 3 }
        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField {
                id: stockInput
                Layout.fillWidth: true
                placeholderText: i18n("Add a symbol, e.g. AAPL or ^SPX")
                onAccepted: addStockBtn.clicked()
            }
            QQC2.Button {
                id: addStockBtn
                text: i18n("Add")
                icon.name: "list-add"
                onClicked: {
                    var s = stockInput.text.trim().toUpperCase();
                    if (s.length === 0) return;
                    for (var i = 0; i < stockModel.count; i++)
                        if (stockModel.get(i).symbol === s) { stockInput.text = ""; return; }
                    stockModel.append({ symbol: s });
                    syncStocks();
                    stockInput.text = "";
                }
            }
        }
        QQC2.Label {
            text: i18n("US tickers like AAPL work as-is. Use ^SPX or ^DJI for indices, or add a suffix such as VOD.UK.")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Flow {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Repeater {
                model: stockModel
                delegate: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                    implicitHeight: chipRow.implicitHeight + Kirigami.Units.smallSpacing
                    implicitWidth: chipRow.implicitWidth + Kirigami.Units.largeSpacing
                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 2
                        QQC2.Label { text: model.symbol; font.weight: Font.DemiBold; leftPadding: Kirigami.Units.smallSpacing }
                        QQC2.ToolButton {
                            icon.name: "window-close"
                            icon.width: Kirigami.Units.iconSizes.small
                            icon.height: Kirigami.Units.iconSizes.small
                            onClicked: { stockModel.remove(index); syncStocks(); }
                        }
                    }
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ============ NEWS ============
        Kirigami.Heading { text: i18n("News feed"); level: 3 }
        RowLayout {
            Layout.fillWidth: true
            QQC2.Label { text: i18n("Source:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 5 }
            QQC2.ComboBox {
                id: newsPreset
                Layout.fillWidth: true
                textRole: "label"
                model: [
                    { label: i18n("Google News — Top stories"), url: "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en" },
                    { label: i18n("BBC News — World"), url: "http://feeds.bbci.co.uk/news/world/rss.xml" },
                    { label: i18n("Reuters — Top news"), url: "https://www.reutersagency.com/feed/?best-topics=top-news&post_type=best" },
                    { label: i18n("NPR — News"), url: "https://feeds.npr.org/1001/rss.xml" },
                    { label: i18n("Ars Technica"), url: "http://feeds.arstechnica.com/arstechnica/index" },
                    { label: i18n("Custom…"), url: "" }
                ]
                onActivated: {
                    var u = model[currentIndex].url;
                    if (u.length > 0) newsUrl.text = u;
                }
            }
        }
        QQC2.TextField {
            id: newsUrl
            Layout.fillWidth: true
            placeholderText: i18n("RSS or Atom feed URL")
            text: plasmoid.configuration.newsFeedUrl
        }
        QQC2.Label {
            text: i18n("Pick a source, or choose Custom and paste any RSS/Atom feed URL.")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
        }

        Kirigami.Separator { Layout.fillWidth: true }

        // ============ UPDATES ============
        Kirigami.Heading { text: i18n("Updates"); level: 3 }
        RowLayout {
            QQC2.Label { text: i18n("Refresh every:"); Layout.preferredWidth: Kirigami.Units.gridUnit * 9 }
            QQC2.SpinBox {
                id: refreshSpin
                from: 5; to: 240; stepSize: 5
                value: plasmoid.configuration.refreshIntervalMinutes
                textFromValue: function (v) { return i18n("%1 minutes", v); }
                valueFromText: function (t) { return parseInt(t); }
            }
        }

    }
}
