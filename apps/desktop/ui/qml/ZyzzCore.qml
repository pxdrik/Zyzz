import QtQuick

Item {
    id: root
    property string aiState: "idle"

    // ── State-driven color ──
    property color coreColor: {
        switch (aiState) {
            case "listening": return "#06b6d4"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            case "error": return "#ef4444"
            default: return "#3b82f6"
        }
    }

    property real intensity: {
        switch (aiState) {
            case "listening": return 0.9
            case "thinking": return 0.75
            case "speaking": return 0.85
            case "error": return 1.0
            default: return 0.45
        }
    }

    property real breathSpeed: {
        switch (aiState) {
            case "listening": return 1800
            case "thinking": return 1000
            case "speaking": return 1400
            case "error": return 500
            default: return 3500
        }
    }

    Behavior on coreColor { ColorAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
    Behavior on intensity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }

    // ── Global breath ──
    property real breath: 1.0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        NumberAnimation { to: 1.04; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.97; duration: root.breathSpeed; easing.type: Easing.InOutSine }
    }

    // ── Orbit angles (continuous, GPU-accelerated via Item rotation) ──
    property real orbit1Angle: 0
    property real orbit2Angle: 0
    property real orbit3Angle: 0
    property real innerAngle: 0

    NumberAnimation on orbit1Angle { from: 0; to: 360; duration: 14000; loops: Animation.Infinite }
    NumberAnimation on orbit2Angle { from: 360; to: 0; duration: 20000; loops: Animation.Infinite }
    NumberAnimation on orbit3Angle { from: 0; to: 360; duration: 28000; loops: Animation.Infinite }
    NumberAnimation on innerAngle { from: 0; to: 360; duration: 6000; loops: Animation.Infinite }

    // ── Core glow (repaints only on color/breath change) ──
    Canvas {
        id: coreGlow
        anchors.centerIn: parent
        width: root.width * 0.55 * root.breath
        height: width

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2;
            ctx.clearRect(0, 0, width, height);

            var g = ctx.createRadialGradient(cx * 0.85, cy * 0.8, 0, cx, cy, r);
            g.addColorStop(0, Qt.rgba(1, 1, 1, 0.85));
            g.addColorStop(0.08, Qt.rgba(
                root.coreColor.r * 0.6 + 0.4,
                root.coreColor.g * 0.6 + 0.4,
                root.coreColor.b * 0.6 + 0.4, 0.75));
            g.addColorStop(0.35, Qt.rgba(
                root.coreColor.r * 0.3,
                root.coreColor.g * 0.3,
                root.coreColor.b * 0.3, 0.45));
            g.addColorStop(0.7, Qt.rgba(
                root.coreColor.r * 0.1,
                root.coreColor.g * 0.1,
                root.coreColor.b * 0.1, 0.15));
            g.addColorStop(1, "transparent");

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = g;
            ctx.fill();
        }

        Connections {
            target: root
            function onCoreColorChanged() { coreGlow.requestPaint() }
            function onBreathChanged() { coreGlow.requestPaint() }
        }
    }

    // ── Orbit Ring 1 — innermost ──
    Canvas {
        id: ring1
        anchors.centerIn: parent
        width: root.width * 0.68 * root.breath
        height: width
        rotation: root.orbit1Angle
        opacity: 0.35 * root.intensity

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 3;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1.2;
            ctx.lineCap = "round";

            // Arc segment 1
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0.3, 1.8);
            ctx.stroke();

            // Arc segment 2
            ctx.beginPath();
            ctx.arc(cx, cy, r, 3.6, 5.2);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ring1.requestPaint() }
        }
    }

    // ── Orbit Ring 2 — middle ──
    Canvas {
        id: ring2
        anchors.centerIn: parent
        width: root.width * 0.82 * root.breath
        height: width
        rotation: root.orbit2Angle
        opacity: 0.22 * root.intensity

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 3;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.8;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0.5, 2.2);
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, r, 2.8, 3.6);
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(cx, cy, r, 4.5, 5.8);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ring2.requestPaint() }
        }
    }

    // ── Orbit Ring 3 — outermost ──
    Canvas {
        id: ring3
        anchors.centerIn: parent
        width: root.width * 0.95 * root.breath
        height: width
        rotation: root.orbit3Angle
        opacity: 0.12 * root.intensity

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 3;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.6;
            ctx.lineCap = "round";
            ctx.setLineDash([4, 16]);

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { ring3.requestPaint() }
        }
    }

    // ── Inner energy arcs (fast rotation) ──
    Canvas {
        id: energyArcs
        anchors.centerIn: parent
        width: root.width * 0.5 * root.breath
        height: width
        rotation: root.innerAngle
        opacity: 0.2 * root.intensity

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 6;
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.coreColor;
            ctx.lineCap = "round";

            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 0.7);
            ctx.stroke();

            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(cx, cy, r * 0.75, 2.5, 3.3);
            ctx.stroke();

            ctx.lineWidth = 1.2;
            ctx.beginPath();
            ctx.arc(cx, cy, r, Math.PI + 0.2, Math.PI + 0.9);
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { energyArcs.requestPaint() }
        }
    }

    // ── Orbital particles — Ring 1 ──
    Repeater {
        model: 4
        Rectangle {
            property real a: index * 90 + root.orbit1Angle * 1.3
            property real r: root.width * 0.34 * root.breath
            x: root.width / 2 + Math.cos(a * Math.PI / 180) * r - width / 2
            y: root.height / 2 + Math.sin(a * Math.PI / 180) * r - height / 2
            width: 3; height: 3; radius: 1.5
            color: root.coreColor
            opacity: (0.4 + (index % 2) * 0.3) * root.intensity
            Behavior on color { ColorAnimation { duration: 1200 } }
        }
    }

    // ── Orbital particles — Ring 2 ──
    Repeater {
        model: 3
        Rectangle {
            property real a: index * 120 + root.orbit2Angle * 0.9
            property real r: root.width * 0.41 * root.breath
            x: root.width / 2 + Math.cos(a * Math.PI / 180) * r - width / 2
            y: root.height / 2 + Math.sin(a * Math.PI / 180) * r - height / 2
            width: 2; height: 2; radius: 1
            color: root.coreColor
            opacity: 0.3 * root.intensity
            Behavior on color { ColorAnimation { duration: 1200 } }
        }
    }

    // ── Orbital particles — Ring 3 (outer, faint) ──
    Repeater {
        model: 2
        Rectangle {
            property real a: index * 180 + root.orbit3Angle * 0.6
            property real r: root.width * 0.475 * root.breath
            x: root.width / 2 + Math.cos(a * Math.PI / 180) * r - width / 2
            y: root.height / 2 + Math.sin(a * Math.PI / 180) * r - height / 2
            width: 2; height: 2; radius: 1
            color: root.coreColor
            opacity: 0.15 * root.intensity
            Behavior on color { ColorAnimation { duration: 1200 } }
        }
    }

    // ── Core bright edge ──
    Canvas {
        id: coreEdge
        anchors.centerIn: parent
        width: root.width * 0.38 * root.breath
        height: width

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2, r = width / 2 - 1;
            ctx.clearRect(0, 0, width, height);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.strokeStyle = Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.25 * root.intensity);
            ctx.lineWidth = 1;
            ctx.stroke();
        }

        Connections {
            target: root
            function onCoreColorChanged() { coreEdge.requestPaint() }
            function onIntensityChanged() { coreEdge.requestPaint() }
        }
    }

    // ── Core center point ──
    Rectangle {
        anchors.centerIn: parent
        width: 5 * root.breath
        height: width
        radius: width / 2
        color: "#ffffff"

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: root.breathSpeed; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.95; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        }
    }
}
