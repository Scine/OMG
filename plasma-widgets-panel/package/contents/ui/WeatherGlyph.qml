import QtQuick
import org.kde.kirigami as Kirigami

// A clean, flat weather glyph drawn with Canvas.
// category: "sun" | "moon" | "partly" | "cloud" | "rain" | "snow" | "storm" | "fog"
Canvas {
    id: glyph
    property string category: "sun"
    property real moonPhase: 0.0   // 0..1 for the moon glyph
    width: Kirigami.Units.iconSizes.enormous
    height: Kirigami.Units.iconSizes.enormous

    onCategoryChanged: requestPaint()
    onMoonPhaseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var w = width, h = height;
        var cx = w / 2, cy = h / 2;

        function sun(scx, scy, r) {
            var g = ctx.createRadialGradient(scx - r * 0.25, scy - r * 0.25, r * 0.1, scx, scy, r);
            g.addColorStop(0, "#ffd23f");
            g.addColorStop(1, "#f7941d");
            ctx.fillStyle = g;
            ctx.beginPath();
            ctx.arc(scx, scy, r, 0, Math.PI * 2);
            ctx.fill();
        }

        function cloud(ccx, ccy, s, color) {
            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.arc(ccx - s * 0.55, ccy, s * 0.45, 0, Math.PI * 2);
            ctx.arc(ccx, ccy - s * 0.28, s * 0.58, 0, Math.PI * 2);
            ctx.arc(ccx + s * 0.6, ccy, s * 0.5, 0, Math.PI * 2);
            ctx.rect(ccx - s, ccy, s * 1.6, s * 0.55);
            ctx.fill();
        }

        var cloudGrey = "#9aa6b8";
        var cloudGreyDark = "#6b7686";

        if (category === "sun") {
            // rays
            ctx.strokeStyle = "#f7b733";
            ctx.lineWidth = Math.max(2, w * 0.03);
            ctx.lineCap = "round";
            var rr = w * 0.42;
            for (var i = 0; i < 8; i++) {
                var a = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * rr * 0.72, cy + Math.sin(a) * rr * 0.72);
                ctx.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
                ctx.stroke();
            }
            sun(cx, cy, w * 0.27);
        } else if (category === "moon") {
            // crescent via two overlapping discs
            ctx.fillStyle = "#cdd6e8";
            ctx.beginPath();
            ctx.arc(cx, cy, w * 0.30, 0, Math.PI * 2);
            ctx.fill();
            // shadow disc offset by phase
            var off = (moonPhase < 0.5 ? 1 : -1) * w * 0.20;
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.arc(cx + off, cy - w * 0.04, w * 0.30, 0, Math.PI * 2);
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        } else if (category === "partly") {
            sun(cx + w * 0.12, cy - h * 0.14, w * 0.20);
            cloud(cx - w * 0.04, cy + h * 0.10, w * 0.26, cloudGrey);
        } else if (category === "cloud" || category === "fog") {
            cloud(cx, cy - h * 0.05, w * 0.3, cloudGrey);
            if (category === "fog") {
                ctx.strokeStyle = cloudGreyDark;
                ctx.lineWidth = Math.max(2, w * 0.025);
                ctx.lineCap = "round";
                for (var f = 0; f < 3; f++) {
                    var fy = cy + h * 0.22 + f * h * 0.09;
                    ctx.beginPath();
                    ctx.moveTo(cx - w * 0.28, fy);
                    ctx.lineTo(cx + w * 0.28, fy);
                    ctx.stroke();
                }
            }
        } else if (category === "rain" || category === "storm" || category === "snow") {
            cloud(cx, cy - h * 0.12, w * 0.28, category === "storm" ? cloudGreyDark : cloudGrey);
            if (category === "snow") {
                ctx.fillStyle = "#cfe3f5";
                for (var s = 0; s < 3; s++) {
                    ctx.beginPath();
                    ctx.arc(cx - w * 0.18 + s * w * 0.18, cy + h * 0.26, w * 0.04, 0, Math.PI * 2);
                    ctx.fill();
                }
            } else {
                ctx.strokeStyle = "#4aa3df";
                ctx.lineWidth = Math.max(2, w * 0.035);
                ctx.lineCap = "round";
                for (var d = 0; d < 3; d++) {
                    var dx = cx - w * 0.18 + d * w * 0.18;
                    ctx.beginPath();
                    ctx.moveTo(dx, cy + h * 0.18);
                    ctx.lineTo(dx - w * 0.04, cy + h * 0.30);
                    ctx.stroke();
                }
                if (category === "storm") {
                    ctx.fillStyle = "#ffd23f";
                    ctx.beginPath();
                    ctx.moveTo(cx + w * 0.02, cy + h * 0.14);
                    ctx.lineTo(cx - w * 0.10, cy + h * 0.32);
                    ctx.lineTo(cx + w * 0.0, cy + h * 0.32);
                    ctx.lineTo(cx - w * 0.06, cy + h * 0.46);
                    ctx.lineTo(cx + w * 0.14, cy + h * 0.24);
                    ctx.lineTo(cx + w * 0.04, cy + h * 0.24);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        } else {
            sun(cx, cy, w * 0.27);
        }
    }
}
