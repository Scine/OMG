import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// One metric row: icon + label on the left, value on the right.
Rectangle {
    id: tile
    property string iconName: ""
    property string label: ""
    property string value: ""
    property string tone: "neutral"   // neutral | good | warn | bad
    property real arrowAngle: -1      // wind direction in degrees; <0 hides

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 2.4
    radius: Kirigami.Units.smallSpacing
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

    function toneColor() {
        if (tone === "good") return Kirigami.Theme.positiveTextColor;
        if (tone === "warn") return Kirigami.Theme.neutralTextColor;
        if (tone === "bad") return Kirigami.Theme.negativeTextColor;
        return Kirigami.Theme.textColor;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing + 2
        anchors.rightMargin: Kirigami.Units.smallSpacing + 2
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: tile.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            opacity: 0.8
        }
        PlasmaComponents.Label {
            text: tile.label
            font: Kirigami.Theme.smallFont
            opacity: 0.85
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // optional wind-direction arrow
        Kirigami.Icon {
            visible: tile.arrowAngle >= 0
            source: "draw-arrow-up"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
            rotation: tile.arrowAngle + 180   // meteorological: arrow points where wind goes
            opacity: 0.8
        }

        PlasmaComponents.Label {
            text: tile.value
            font.weight: Font.DemiBold
            color: tile.toneColor()
            horizontalAlignment: Text.AlignRight
        }
    }
}
