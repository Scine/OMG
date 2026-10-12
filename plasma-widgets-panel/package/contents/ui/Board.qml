import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: board
    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    Layout.preferredWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            Kirigami.Heading {
                text: i18n("Widgets")
                level: 2
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                text: root.lastUpdated.getTime() > 0
                    ? i18n("Updated %1", Qt.formatTime(root.lastUpdated, Qt.locale().timeFormat(Locale.ShortFormat)))
                    : ""
            }
            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh")
                onClicked: root.refreshAll()
                enabled: !(root.weatherLoading || root.stocksLoading || root.newsLoading)
            }
            PlasmaComponents.ToolButton {
                icon.name: "configure"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Configure…")
                onClicked: Plasmoid.internalAction("configure").trigger()
            }
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width: board.width - Kirigami.Units.smallSpacing * 2
                spacing: Kirigami.Units.largeSpacing

                WeatherCard {}
                StocksCard {}
                NewsCard {}
            }
        }
    }
}
