import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// A rounded card frame with a title row and a default content slot.
Rectangle {
    id: card
    property string title: ""
    property string iconName: ""
    property bool loading: false
    property string errorText: ""
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.gridUnit / 2
    color: Kirigami.Theme.backgroundColor
    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    border.width: 1

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: card.iconName
                visible: card.iconName.length > 0
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            Kirigami.Heading {
                text: card.title
                level: 4
                Layout.fillWidth: true
            }
            PlasmaComponents.BusyIndicator {
                running: card.loading
                visible: card.loading
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
        }

        PlasmaComponents.Label {
            visible: card.errorText.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.negativeTextColor
            text: card.errorText.length > 0 ? i18n("Couldn't load: %1", card.errorText) : ""
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
        }
    }
}
