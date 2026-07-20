import QtQuick

Item {
    id: root
    property string aiState: "idle"

    property color coreColor: {
        switch (aiState) {
            case "listening": return "#00f0ff"
            case "thinking": return "#a855f7"
            case "speaking": return "#22c55e"
            case "error": return "#ef4444"
            default: return "#00f0ff"
        }
    }

    property real intensity: {
        switch (aiState) {
            case "listening": return 1.0
            case "thinking": return 0.8
            case "speaking": return 0.9
            case "error": return 1.0
            default: return 0.5
        }
    }

    property real pulseSpeed: {
        switch (aiState) {
            case "listening": return 700
            case "thinking": return 1000
            case "speaking": return 500
            case "error": return 300
            default: return 2500
        }
    }

    Behavior on coreColor { ColorAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    Behavior on intensity { NumberAnimation { duration: 800 } }

    // Pulse
    property real pulse: 1.0
    SequentialAnimation on pulse {
        loops: Animation.Infinite
        NumberAnimation { to: 1.08; duration: root.pulseSpeed; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: root.pulseSpeed; easing.type: Easing.InOutSine }
    }

    // Ring rotations
    property real ring1Angle: 0
    property real ring2Angle: 0
    property real ring3Angle: 0
    NumberAnimation on ring1Angle { from: 0; to: 360; duration: 12000; loops: Animation.Infinite }
    NumberAnimation on ring2Angle { from: 360; to: 0; duration: 18000; loops: Animation.Infinite }
    NumberAnimation on ring3Angle { from: 0; to: 360; duration: 25000; loops: Animation.Infinite }

    // Inner energy rotation
    property real energyAngle: 0
    NumberAnimation on energyAngle { from: 0; to: 360; duration: 4000; loops: Animation.Infinite }

    // ── Outer glow ──
    Canvas {
        id: outerGlow
        anchors.centerIn: parent
        width: root.width * 1.8
        height: width
        opacity: root.intensity * 0.4

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2;
            ctx.clearRect(0, 0, width, height);
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
            g.addColorStop(0, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.2));
            g.addColorStop(0.3, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.06));
            g.addColorStop(1, "transparent");
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }

        Connections {
            target: root
            function onCoreColorChanged() { outerGlow.requestPaint() }
            function onIntensityChanged() { outerGlow.requestPaint() }
        }
    }

    // ── Ring 3 (outermost) — dashed ──
    Canvas {
        id: ringCanvas3
        anchors.centerIn: parent
        width: root.width * 1.15 * root.pulse
        height: width
        rotation: root.ring3Angle
        opacity: 0.12

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 2;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.5;
            ctx.setLineDash([3, 12]);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ringCanvas3.requestPaint() }
            function onPulseChanged() { ringCanvas3.requestPaint() }
        }
    }

    // ── Ring 2 (middle) ──
    Canvas {
        id: ringCanvas2
        anchors.centerIn: parent
        width: root.width * 0.95 * root.pulse
        height: width
        rotation: root.ring2Angle
        opacity: 0.2

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 2;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1;
            ctx.setLineDash([20, 30]);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ringCanvas2.requestPaint() }
            function onPulseChanged() { ringCanvas2.requestPaint() }
        }
    }

    // ── Ring 1 (inner) — solid thin ──
    Canvas {
        id: ringCanvas1
        anchors.centerIn: parent
        width: root.width * 0.78 * root.pulse
        height: width
        rotation: root.ring1Angle
        opacity: 0.3

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 2;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1.5;
            ctx.setLineDash([8, 15]);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();

            // Arc accent
            ctx.lineWidth = 2;
            ctx.setLineDash([]);
            ctx.beginPath();
            ctx.arc(cx, cy, r, -0.3, 0.8);
            ctx.strokeStyle = Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.6);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ringCanvas1.requestPaint() }
            function onPulseChanged() { ringCanvas1.requestPaint() }
        }
    }

    // ── Core sphere ──
    Canvas {
        id: coreCanvas
        anchors.centerIn: parent
        width: root.width * 0.45 * root.pulse
        height: width

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2;
            ctx.clearRect(0, 0, width, height);

            // Core gradient
            var g = ctx.createRadialGradient(cx * 0.8, cy * 0.7, 0, cx, cy, r);
            g.addColorStop(0, Qt.rgba(1, 1, 1, 0.9));
            g.addColorStop(0.15, Qt.rgba(root.coreColor.r * 0.7 + 0.3, root.coreColor.g * 0.7 + 0.3, root.coreColor.b * 0.7 + 0.3, 0.85));
            g.addColorStop(0.5, Qt.rgba(root.coreColor.r * 0.4, root.coreColor.g * 0.4, root.coreColor.b * 0.4, 0.7));
            g.addColorStop(1.0, Qt.rgba(root.coreColor.r * 0.1, root.coreColor.g * 0.1, root.coreColor.b * 0.1, 0.4));
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = g;
            ctx.fill();

            // Bright edge ring
            ctx.beginPath();
            ctx.arc(cx, cy, r - 1, 0, 2 * Math.PI);
            ctx.strokeStyle = Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.5 * root.intensity);
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { coreCanvas.requestPaint() }
            function onPulseChanged() { coreCanvas.requestPaint() }
            function onIntensityChanged() { coreCanvas.requestPaint() }
        }
    }

    // ── Orbiting energy dots on Ring 1 ──
    Repeater {
        model: 6
        Rectangle {
            property real angle: index * 60 + root.ring1Angle * 1.5
            property real orbitR: root.width * 0.39 * root.pulse
            x: root.width / 2 + Math.cos(angle * Math.PI / 180) * orbitR - width / 2
            y: root.height / 2 + Math.sin(angle * Math.PI / 180) * orbitR - height / 2
            width: 3
            height: 3
            radius: 1.5
            color: root.coreColor
            opacity: 0.5 + (index % 2) * 0.3
            Behavior on color { ColorAnimation { duration: 800 } }
        }
    }

    // ── Orbiting dots on Ring 2 ──
    Repeater {
        model: 4
        Rectangle {
            property real angle: index * 90 + root.ring2Angle * 0.8
            property real orbitR: root.width * 0.475 * root.pulse
            x: root.width / 2 + Math.cos(angle * Math.PI / 180) * orbitR - width / 2
            y: root.height / 2 + Math.sin(angle * Math.PI / 180) * orbitR - height / 2
            width: 2
            height: 2
            radius: 1
            color: root.coreColor
            opacity: 0.3
            Behavior on color { ColorAnimation { duration: 800 } }
        }
    }

    // ── Inner energy arcs ──
    Canvas {
        id: energyArcs
        anchors.centerIn: parent
        width: root.width * 0.55 * root.pulse
        height: width
        rotation: root.energyAngle
        opacity: 0.25 * root.intensity

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 4;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 0.6);
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, r, Math.PI, Math.PI + 0.8);
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, r * 0.7, Math.PI * 0.5, Math.PI * 0.5 + 0.5);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { energyArcs.requestPaint() }
            function onIntensityChanged() { energyArcs.requestPaint() }
        }
    }

    // ── "ZYZZ" label below core ──
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: root.height * 0.38
        text: "Z Y Z Z"
        color: root.coreColor
        opacity: 0.25
        font.pixelSize: 11
        font.letterSpacing: 8
        font.family: "Consolas"
        font.bold: true
        Behavior on color { ColorAnimation { duration: 800 } }
    }
}
