import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Rectangle {
    id: wcard
    property var applet
    property var wx: applet ? applet.weatherData : null

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.gridUnit / 2
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    border.width: 1

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // ---- location switcher ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: "mark-location"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                opacity: 0.8
            }
            PlasmaComponents.Label {
                text: Plasmoid.configuration.locationName
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.weight: Font.DemiBold
            }
            PlasmaComponents.ToolButton {
                visible: applet.locations.length > 1
                icon.name: "go-previous"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Previous location")
                onClicked: applet.cycleLocation(-1)
            }
            PlasmaComponents.Label {
                visible: applet.locations.length > 1
                text: (applet.activeLocation + 1) + "/" + applet.locations.length
                font: Kirigami.Theme.smallFont
                opacity: 0.6
            }
            PlasmaComponents.ToolButton {
                visible: applet.locations.length > 1
                icon.name: "go-next"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Next location")
                onClicked: applet.cycleLocation(1)
            }
        }

        // ---- hero: temp | glyph | high/low ----
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                spacing: 0
                RowLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        text: wcard.wx ? wcard.wx.temperature : "--"
                        font.pixelSize: Kirigami.Units.gridUnit * 2.6
                        font.weight: Font.Light
                    }
                    PlasmaComponents.Label {
                        text: wcard.wx ? wcard.wx.tempSymbol : ""
                        font.pixelSize: Kirigami.Units.gridUnit * 1.3
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: Kirigami.Units.smallSpacing
                    }
                }
                PlasmaComponents.Label {
                    text: wcard.wx ? wcard.wx.condition : i18n("Loading…")
                    font.weight: Font.DemiBold
                }
                PlasmaComponents.Label {
                    visible: wcard.wx !== null
                    text: wcard.wx ? i18n("Feels like %1%2", wcard.wx.feelsLike, wcard.wx.tempSymbol) : ""
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
            }

            Item { Layout.fillWidth: true }

            WeatherGlyph {
                Layout.alignment: Qt.AlignVCenter
                width: Kirigami.Units.iconSizes.huge * 1.6
                height: Kirigami.Units.iconSizes.huge * 1.6
                category: wcard.wx ? wcard.wx.glyph : "sun"
                moonPhase: wcard.wx && wcard.wx.moon ? wcard.wx.moon.phase : 0
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Kirigami.Units.smallSpacing
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label { text: i18n("High"); font: Kirigami.Theme.smallFont; opacity: 0.7; Layout.alignment: Qt.AlignRight }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignRight
                        text: (wcard.wx && wcard.wx.high !== null) ? (wcard.wx.high + "°") : "--"
                        color: Kirigami.Theme.neutralTextColor
                        font.weight: Font.DemiBold
                    }
                }
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label { text: i18n("Low"); font: Kirigami.Theme.smallFont; opacity: 0.7; Layout.alignment: Qt.AlignRight }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignRight
                        text: (wcard.wx && wcard.wx.low !== null) ? (wcard.wx.low + "°") : "--"
                        color: Kirigami.Theme.highlightColor
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        PlasmaComponents.Label {
            visible: applet.weatherError.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.negativeTextColor
            text: i18n("Couldn't load weather: %1", applet.weatherError)
        }

        // ---- tabs ----
        SegmentedControl {
            id: tabs
            Layout.topMargin: Kirigami.Units.smallSpacing
            labels: [i18n("Details"), i18n("Forecast"), i18n("Radar")]
            currentIndex: 0
        }

        // ---- tab content ----
        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabs.currentIndex

            // === DETAILS ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    DetailTile { iconName: "temperature-normal"; label: i18n("Humidity"); value: wcard.wx ? wcard.wx.humidity + "%" : "--" }
                    DetailTile { iconName: "weather-clouds"; label: i18n("Pressure"); value: wcard.wx && wcard.wx.pressure ? wcard.wx.pressure : "--" }
                    DetailTile { iconName: "flag"; label: i18n("Wind"); value: wcard.wx ? (wcard.wx.windSpeed + " " + wcard.wx.windSymbol + (wcard.wx.windCompass ? " " + wcard.wx.windCompass : "")) : "--"; arrowAngle: wcard.wx && wcard.wx.windDir !== undefined ? wcard.wx.windDir : -1 }
                    DetailTile { iconName: "temperature-cold"; label: i18n("Dew point"); value: wcard.wx && wcard.wx.dewPoint ? wcard.wx.dewPoint : "--" }
                    DetailTile { iconName: "edit-select-all"; label: i18n("Visibility"); value: wcard.wx && wcard.wx.visibility ? wcard.wx.visibility : "--" }
                    DetailTile { iconName: "weather-showers"; label: i18n("Precipitation"); value: wcard.wx && wcard.wx.precipSum !== null ? (wcard.wx.precipSum + " " + wcard.wx.precipUnit) : "--" }
                }

                // sun + moon panels
                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    SunArc {
                        progress: wcard.wx ? wcard.wx.dayProgress : -1
                        riseLabel: wcard.wx ? wcard.wx.sunrise : ""
                        setLabel: wcard.wx ? wcard.wx.sunset : ""
                        isDay: wcard.wx ? wcard.wx.isDay : true
                        caption: {
                            if (!wcard.wx || isNaN(wcard.wx.dayLengthMin)) return "";
                            var m = wcard.wx.dayLengthMin;
                            return i18n("Daylight: %1h %2m", Math.floor(m / 60), Math.round(m % 60));
                        }
                    }
                    MoonPanel {
                        phase: wcard.wx && wcard.wx.moon ? wcard.wx.moon.phase : 0
                        phaseName: wcard.wx && wcard.wx.moon ? wcard.wx.moon.name : ""
                        illumination: wcard.wx && wcard.wx.moon ? wcard.wx.moon.illumination : 0
                    }
                }

                // extra conditions
                GridLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    columns: 2
                    columnSpacing: Kirigami.Units.smallSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    DetailTile {
                        iconName: "weather-clear"; label: i18n("UV Index")
                        value: wcard.wx && wcard.wx.uv !== null ? (wcard.wx.uv + " (" + wcard.wx.uvLabel + ")") : "--"
                        tone: wcard.wx && wcard.wx.uv !== null ? (wcard.wx.uv >= 8 ? "bad" : (wcard.wx.uv >= 6 ? "warn" : "neutral")) : "neutral"
                    }
                    DetailTile {
                        iconName: "cloudy"; label: i18n("Air Quality")
                        value: applet.airData && applet.airData.aqi !== null ? (i18n("AQI %1 · %2", applet.airData.aqi, applet.airData.label)) : "--"
                        tone: applet.airData ? applet.airData.tone : "neutral"
                    }
                    DetailTile {
                        iconName: "preferences-desktop-color"; label: i18n("Pollen")
                        value: applet.airData && applet.airData.pollen ? applet.airData.pollen : "--"
                    }
                    DetailTile {
                        iconName: "preferences-system-network"; label: i18n("Space Weather")
                        value: applet.spaceData ? (i18n("Kp %1 · %2", applet.spaceData.kp, applet.spaceData.g)) : "--"
                        tone: applet.spaceData ? applet.spaceData.tone : "neutral"
                    }
                    DetailTile {
                        iconName: "weather-snow"; label: i18n("Snowfall")
                        value: wcard.wx && wcard.wx.snowSum !== null ? (wcard.wx.snowSum + " " + wcard.wx.snowUnit) : "--"
                    }
                    DetailTile {
                        iconName: "appointment-new"; label: i18n("Local time")
                        value: wcard.wx && wcard.wx.localTime ? wcard.wx.localTime : "--"
                    }
                }

                // alerts
                Repeater {
                    model: applet.alertsData
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        implicitHeight: alertRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: Kirigami.Units.smallSpacing
                        color: Qt.rgba(Kirigami.Theme.neutralTextColor.r, Kirigami.Theme.neutralTextColor.g, Kirigami.Theme.neutralTextColor.b, 0.14)
                        RowLayout {
                            id: alertRow
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            Kirigami.Icon { source: "data-warning"; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: modelData.event + (modelData.severity ? " · " + modelData.severity : "")
                                color: modelData.tone === "bad" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.neutralTextColor
                                font.weight: Font.DemiBold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // === FORECAST ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: wcard.wx ? wcard.wx.forecast : []
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing / 2
                        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                        spacing: Kirigami.Units.largeSpacing

                        PlasmaComponents.Label {
                            text: index === 0 ? i18n("Today") : Qt.formatDate(new Date(modelData.date), "ddd")
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            font.weight: index === 0 ? Font.DemiBold : Font.Normal
                        }
                        WeatherGlyph {
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            category: modelData.glyph
                        }
                        PlasmaComponents.Label {
                            visible: modelData.precip > 0
                            text: modelData.precip + (wcard.wx ? " " + wcard.wx.precipUnit : "")
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.highlightColor
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: modelData.high + "°"
                            font.weight: Font.DemiBold
                            color: Kirigami.Theme.neutralTextColor
                        }
                        PlasmaComponents.Label {
                            text: modelData.low + "°"
                            opacity: 0.7
                            color: Kirigami.Theme.highlightColor
                        }
                    }
                }
            }

            // === RADAR ===
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: i18n("7-day precipitation outlook")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
                Repeater {
                    model: wcard.wx ? wcard.wx.forecast : []
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        PlasmaComponents.Label {
                            text: index === 0 ? i18n("Today") : Qt.formatDate(new Date(modelData.date), "ddd")
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                            font: Kirigami.Theme.smallFont
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Kirigami.Units.gridUnit * 0.8
                            radius: height / 2
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                height: parent.height
                                radius: height / 2
                                color: Kirigami.Theme.highlightColor
                                // scale: 10 units of precip fills the bar
                                width: Math.min(1.0, (modelData.precip || 0) / 10.0) * parent.width
                            }
                        }
                        PlasmaComponents.Label {
                            text: (modelData.precip || 0) + (wcard.wx ? " " + wcard.wx.precipUnit : "")
                            font: Kirigami.Theme.smallFont
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
                PlasmaComponents.Button {
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.alignment: Qt.AlignHCenter
                    icon.name: "globe"
                    text: i18n("Open live radar map")
                    onClicked: {
                        var lat = Plasmoid.configuration.latitude;
                        var lon = Plasmoid.configuration.longitude;
                        Qt.openUrlExternally("https://www.rainviewer.com/map.html?loc=" + lat + "," + lon + ",7");
                    }
                }
            }
        }
    }
}
