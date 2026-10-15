import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// A night-sky panel showing the current moon phase, name and illumination.
Rectangle {
    id: panel
    property real phase: 0.0         // 0..1 synodic
    property string phaseName: ""
    property int illumination: 0     // 0..100

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 9
    radius: Kirigami.Units.gridUnit / 2
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#15182a" }
        GradientStop { position: 1.0; color: "#241d38" }
    }
    clip: true

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "rgba(255,255,255,0.35)";
            var seed = 777;
            function rnd() { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; }
            for (var i = 0; i < 45; i++) {
                ctx.globalAlpha = 0.15 + rnd() * 0.5;
                ctx.beginPath();
                ctx.arc(rnd() * width, rnd() * height, rnd() * 1.2 + 0.3, 0, Math.PI * 2);
                ctx.fill();
            }
            ctx.globalAlpha = 1;
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        Canvas {
            id: moon
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3.4
            Layout.preferredHeight: Kirigami.Units.gridUnit * 3.4

            property real p: panel.phase
            property real illum: panel.illumination / 100.0

            onPChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var w = width, h = height;
                var cx = w / 2, cy = h / 2;
                var R = Math.min(w, h) / 2 - 2;

                // lit disc with soft gradient
                var g = ctx.createRadialGradient(cx - R * 0.3, cy - R * 0.3, R * 0.2, cx, cy, R);
                g.addColorStop(0, "#f4f6ff");
                g.addColorStop(1, "#c3ccdf");
                ctx.fillStyle = g;
                ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill();

                // carve the shadow: a same-size disc offset by illumination
                var dir = (moon.p < 0.5) ? -1 : 1;    // which limb stays lit
                var offset = moon.illum * 2 * R;
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(cx + dir * offset, cy, R, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalCompositeOperation = "source-over";

                // faint rim so a near-new moon is still visible
                ctx.strokeStyle = "rgba(255,255,255,0.18)";
                ctx.lineWidth = 1;
                ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.stroke();
            }
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: panel.phaseName
            color: "#e9ecf7"
            font.weight: Font.DemiBold
        }
        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("%1%% illuminated", panel.illumination)
            color: "#b9a9e8"
            font: Kirigami.Theme.smallFont
        }
    }
}
