import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM
import "../code/fetch.js" as Fetch

KCM.SimpleKCM {
    id: configPage

    property alias cfg_locationName: locationField.text
    property alias cfg_latitude: latField.text
    property alias cfg_longitude: lonField.text
    property alias cfg_stockSymbols: stocksField.text
    property alias cfg_newsFeedUrl: newsField.text
    property alias cfg_refreshIntervalMinutes: refreshSpin.value
    property string cfg_temperatureUnit: tempFahrenheit.checked ? "fahrenheit" : "celsius"
    property string cfg_windSpeedUnit: windMph.checked ? "mph" : "kmh"

    // KCM wrapper import (Plasma 6)
    // declared below via the import alias
    Component.onCompleted: {
        tempFahrenheit.checked = (plasmoid.configuration.temperatureUnit === "fahrenheit");
        tempCelsius.checked = !tempFahrenheit.checked;
        windMph.checked = (plasmoid.configuration.windSpeedUnit === "mph");
        windKmh.checked = !windMph.checked;
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // ---- Location ----
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Location") }

        RowLayout {
            Kirigami.FormData.label: i18n("Search city:")
            QQC2.TextField {
                id: searchField
                placeholderText: i18n("e.g. Portland, Oregon")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                onAccepted: searchButton.clicked()
            }
            QQC2.Button {
                id: searchButton
                text: i18n("Search")
                icon.name: "search"
                onClicked: {
                    if (searchField.text.trim().length === 0) return;
                    resultsCombo.model = [];
                    statusLabel.text = i18n("Searching…");
                    Fetch.geocode(searchField.text, function (err, results) {
                        if (err) { statusLabel.text = i18n("Search failed: %1", err); return; }
                        if (!results || results.length === 0) {
                            statusLabel.text = i18n("No matches found.");
                            return;
                        }
                        var labels = [];
                        configPage._geoResults = results;
                        for (var i = 0; i < results.length; i++) {
                            var r = results[i];
                            var parts = [r.name];
                            if (r.admin1) parts.push(r.admin1);
                            if (r.country) parts.push(r.country);
                            labels.push(parts.join(", "));
                        }
                        resultsCombo.model = labels;
                        statusLabel.text = i18n("Select a result to apply.");
                        resultsCombo.currentIndex = 0;
                    });
                }
            }
        }

        property var _geoResults: []

        QQC2.ComboBox {
            id: resultsCombo
            Kirigami.FormData.label: i18n("Results:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 18
            onActivated: {
                var r = configPage._geoResults[currentIndex];
                if (!r) return;
                locationField.text = r.name + (r.admin1 ? ", " + r.admin1 : "");
                latField.text = "" + r.latitude;
                lonField.text = "" + r.longitude;
                statusLabel.text = i18n("Applied %1 (%2, %3)", locationField.text, r.latitude, r.longitude);
            }
        }

        QQC2.Label {
            id: statusLabel
            Kirigami.FormData.label: ""
            opacity: 0.7
            font: Kirigami.Theme.smallFont
        }

        QQC2.TextField {
            id: locationField
            Kirigami.FormData.label: i18n("Display name:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        }
        QQC2.TextField {
            id: latField
            Kirigami.FormData.label: i18n("Latitude:")
            validator: DoubleValidator { bottom: -90; top: 90 }
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }
        QQC2.TextField {
            id: lonField
            Kirigami.FormData.label: i18n("Longitude:")
            validator: DoubleValidator { bottom: -180; top: 180 }
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
        }

        // ---- Units ----
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Units") }

        RowLayout {
            Kirigami.FormData.label: i18n("Temperature:")
            QQC2.RadioButton { id: tempFahrenheit; text: i18n("Fahrenheit") }
            QQC2.RadioButton { id: tempCelsius; text: i18n("Celsius") }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Wind speed:")
            QQC2.RadioButton { id: windMph; text: i18n("mph") }
            QQC2.RadioButton { id: windKmh; text: i18n("km/h") }
        }

        // ---- Markets ----
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Markets") }

        QQC2.TextField {
            id: stocksField
            Kirigami.FormData.label: i18n("Symbols:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 18
            placeholderText: "AAPL,MSFT,^SPX"
        }
        QQC2.Label {
            text: i18n("Comma-separated. US tickers like AAPL work as-is; use ^SPX, ^DJI for indices, or add an exchange suffix (e.g. VOD.UK).")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        }

        // ---- News ----
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("News") }

        QQC2.TextField {
            id: newsField
            Kirigami.FormData.label: i18n("RSS/Atom feed URL:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        }
        QQC2.Label {
            text: i18n("Any RSS or Atom feed. Default is Google News top stories.")
            font: Kirigami.Theme.smallFont
            opacity: 0.6
        }

        // ---- Refresh ----
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Updates") }

        QQC2.SpinBox {
            id: refreshSpin
            Kirigami.FormData.label: i18n("Refresh every:")
            from: 5
            to: 240
            stepSize: 5
            textFromValue: function (value) { return i18n("%1 min", value); }
        }
    }
}
