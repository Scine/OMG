import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Card {
    id: weatherCard
    title: i18n("Weather — %1", Plasmoid.configuration.locationName)
    iconName: root.weatherData ? root.weatherData.icon : "weather-none-available"
    loading: root.weatherLoading
    errorText: root.weatherError

    // Current conditions
    RowLayout {
        Layout.fillWidth: true
        visible: root.weatherData !== null
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            source: root.weatherData ? root.weatherData.icon : ""
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Kirigami.Heading {
                level: 1
                text: root.weatherData
                    ? (root.weatherData.temperature + root.weatherData.tempSymbol)
                    : ""
            }
            PlasmaComponents.Label {
                text: root.weatherData ? root.weatherData.condition : ""
                font: Kirigami.Theme.smallFont
                opacity: 0.8
            }
            PlasmaComponents.Label {
                visible: root.weatherData !== null
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                text: root.weatherData
                    ? i18n("Feels like %1%2 · Humidity %3%% · Wind %4 %5",
                           root.weatherData.feelsLike, root.weatherData.tempSymbol,
                           root.weatherData.humidity,
                           root.weatherData.windSpeed, root.weatherData.windSymbol)
                    : ""
            }
        }
    }

    // 5-day forecast
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: root.weatherData !== null && root.weatherData.forecast.length > 0

        Repeater {
            model: root.weatherData ? root.weatherData.forecast : []
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font: Kirigami.Theme.smallFont
                    opacity: 0.8
                    text: {
                        var d = new Date(modelData.date);
                        return Qt.formatDate(d, "ddd");
                    }
                }
                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    source: modelData.icon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    font: Kirigami.Theme.smallFont
                    text: modelData.high + "° / " + modelData.low + "°"
                }
            }
        }
    }

    PlasmaComponents.Label {
        visible: root.weatherData === null && !root.weatherLoading && root.weatherError.length === 0
        text: i18n("No data yet.")
        opacity: 0.6
    }
}
