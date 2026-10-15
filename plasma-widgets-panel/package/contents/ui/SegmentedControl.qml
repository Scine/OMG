import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// A rounded segmented tab control. Set `labels` (array) and read `currentIndex`.
Rectangle {
    id: seg
    property var labels: []
    property int currentIndex: 0

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2
    radius: height / 2
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)

    // Sliding highlight
    Rectangle {
        id: thumb
        visible: seg.labels.length > 0
        radius: height / 2
        color: Kirigami.Theme.highlightColor
        y: Kirigami.Units.smallSpacing / 2
        height: parent.height - Kirigami.Units.smallSpacing
        width: seg.labels.length > 0 ? (seg.width / seg.labels.length) - Kirigami.Units.smallSpacing : 0
        x: seg.labels.length > 0
           ? (seg.width / seg.labels.length) * seg.currentIndex + Kirigami.Units.smallSpacing / 2
           : 0
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.fill: parent
        Repeater {
            model: seg.labels
            delegate: Item {
                width: seg.width / seg.labels.length
                height: seg.height
                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: modelData
                    font.weight: index === seg.currentIndex ? Font.DemiBold : Font.Normal
                    color: index === seg.currentIndex
                           ? Kirigami.Theme.highlightedTextColor
                           : Kirigami.Theme.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.currentIndex = index
                }
            }
        }
    }
}
