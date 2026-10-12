import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// A twilight-sky panel with the sun's daily arc and a position marker.
Rectangle {
    id: panel
    property real progress: 0.5        // 0 sunrise .. 1 sunset (may be <0 or >1 at night)
    property string riseLabel: ""
    property string setLabel: ""
    property string caption: ""
    property bool isDay: true
    property color markColor: "#ffd23f"

    Layout.fillWidth: true
    implicitHeight: Kirigami.Units.gridUnit * 9
    radius: Kirigami.Units.gridUnit / 2
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#1d2235" }
        GradientStop { position: 1.0; color: "#2b2340" }
    }
    clip: true

    // faint stars
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "rgba(255,255,255,0.35)";
            var seed = 12345;
            function rnd() { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; }
            for (var i = 0; i < 40; i++) {
                var x = rnd() * width;
                var y = rnd() * height * 0.7;
                var r = rnd() * 1.2 + 0.3;
                ctx.globalAlpha = 0.2 + rnd() * 0.5;
                ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
            }
            ctx.globalAlpha = 1;
        }
    }

    Canvas {
        id: arc
        anchors.fill: parent
        anchors.bottomMargin: Kirigami.Units.gridUnit * 2.2
        anchors.leftMargin: Kirigami.Units.largeSpacing * 2
        anchors.rightMargin: Kirigami.Units.largeSpacing * 2
        anchors.topMargin: Kirigami.Units.largeSpacing

        property real p: Math.max(0, Math.min(1, panel.progress))

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;
            var baseY = h;
            var R = Math.min(w / 2, h);
            var cx = w / 2;

            function pt(t) {
                var a = Math.PI * (1 - t);
                return { x: cx + R * Math.cos(a), y: baseY - R * Math.sin(a) };
            }

            // Full arc, dotted + faint
            ctx.strokeStyle = "rgba(255,255,255,0.28)";
            ctx.lineWidth = 2;
            ctx.setLineDash([3, 5]);
            ctx.beginPath();
            for (var t = 0; t <= 1.0001; t += 0.02) {
                var q = pt(t);
                if (t === 0) ctx.moveTo(q.x, q.y); else ctx.lineTo(q.x, q.y);
            }
            ctx.stroke();

            // Travelled portion, solid
            if (panel.progress > 0 && panel.progress <= 1) {
                ctx.setLineDash([]);
                ctx.strokeStyle = panel.markColor;
                ctx.lineWidth = 2.5;
                ctx.beginPath();
                for (var s = 0; s <= arc.p + 0.0001; s += 0.02) {
                    var r = pt(s);
                    if (s === 0) ctx.moveTo(r.x, r.y); else ctx.lineTo(r.x, r.y);
                }
                ctx.stroke();
            }

            // endpoint dots
            ctx.setLineDash([]);
            ctx.fillStyle = "rgba(255,255,255,0.55)";
            var e0 = pt(0), e1 = pt(1);
            ctx.beginPath(); ctx.arc(e0.x, e0.y, 3, 0, Math.PI * 2); ctx.fill();
            ctx.beginPath(); ctx.arc(e1.x, e1.y, 3, 0, Math.PI * 2); ctx.fill();

            // sun/moon marker
            if (panel.progress >= 0 && panel.progress <= 1) {
                var m = pt(arc.p);
                ctx.fillStyle = panel.markColor;
                ctx.shadowColor = panel.markColor;
                ctx.shadowBlur = 12;
                ctx.beginPath(); ctx.arc(m.x, m.y, 6, 0, Math.PI * 2); ctx.fill();
                ctx.shadowBlur = 0;
            }
        }
        Component.onCompleted: requestPaint()
        onPChanged: requestPaint()
        onWidthChanged: requestPaint()
    }

    // time labels
    PlasmaComponents.Label {
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        text: panel.riseLabel
        color: "#e6ebf5"
        font: Kirigami.Theme.smallFont
    }
    PlasmaComponents.Label {
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        text: panel.setLabel
        color: "#e6ebf5"
        font: Kirigami.Theme.smallFont
    }
    PlasmaComponents.Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        text: panel.caption
        color: "#c9b8ff"
        font: Kirigami.Theme.smallFont
        visible: panel.caption.length > 0
    }
}
