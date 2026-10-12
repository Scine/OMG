import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Card {
    id: stocksCard
    property var applet
    title: i18n("Markets")
    iconName: "office-chart-line"
    loading: applet.stocksLoading
    errorText: applet.stocksError

    Repeater {
        model: applet.stocksData
        delegate: RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label {
                    text: modelData.symbol
                    font.bold: true
                }
                PlasmaComponents.Label {
                    visible: modelData.name.length > 0 && modelData.name !== modelData.symbol
                    text: modelData.name
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                    elide: Text.ElideRight
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                }
            }

            PlasmaComponents.Label {
                text: modelData.valid ? modelData.price : i18n("N/A")
                horizontalAlignment: Text.AlignRight
            }

            PlasmaComponents.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                horizontalAlignment: Text.AlignRight
                visible: modelData.valid
                text: modelData.change + "  " + modelData.changePercent
                color: modelData.up ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
            }
        }
    }

    PlasmaComponents.Label {
        visible: applet.stocksData.length === 0 && !applet.stocksLoading && applet.stocksError.length === 0
        text: i18n("No symbols configured.")
        opacity: 0.6
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        visible: applet.stocksData.length > 0
        font: Kirigami.Theme.smallFont
        opacity: 0.5
        wrapMode: Text.WordWrap
        text: i18n("Change shown vs. today's open. Data from Stooq, may be delayed.")
    }
}
