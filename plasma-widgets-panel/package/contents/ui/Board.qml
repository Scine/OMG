import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: board
    property var applet

    // Roomy, Windows 11-style board. Grows to two columns when wide.
    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 28
    Layout.preferredWidth: Kirigami.Units.gridUnit * 46
    Layout.preferredHeight: Kirigami.Units.gridUnit * 42
    Layout.maximumWidth: Kirigami.Units.gridUnit * 60
    Layout.maximumHeight: Kirigami.Units.gridUnit * 60

    readonly property bool twoColumns: width > Kirigami.Units.gridUnit * 40

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
                text: (board.applet && board.applet.lastUpdated.getTime() > 0)
                    ? i18n("Updated %1", Qt.formatTime(board.applet.lastUpdated, Qt.locale().timeFormat(Locale.ShortFormat)))
                    : ""
            }
            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh")
                onClicked: board.applet.refreshAll()
                enabled: board.applet && !(board.applet.weatherLoading || board.applet.stocksLoading || board.applet.newsLoading)
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

            GridLayout {
                width: board.width - Kirigami.Units.smallSpacing * 2
                columns: board.twoColumns ? 2 : 1
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                // Weather takes the left column (spans both rows when two-column).
                WeatherCard {
                    applet: board.applet
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.rowSpan: board.twoColumns ? 2 : 1
                    Layout.preferredWidth: board.twoColumns ? board.width * 0.5 : board.width
                }
                StocksCard {
                    applet: board.applet
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
                NewsCard {
                    applet: board.applet
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                }
            }
        }
    }
}
