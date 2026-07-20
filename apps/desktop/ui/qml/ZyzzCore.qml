import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string state: "idle"

    // State-dependent properties
    property color glowColor: {
        switch (state) {
            case "listening": return "#00e5ff"
            case "thinking": return "#aa88ff"
            case "speaking": return "#00ff88"
            case "error": return "#ff4466"
            default: return "#4466ff"
        }
    }

    property real glowIntensity: {
        switch (state) {
            case "listening": return 0.9
            case "thinking": return 0.7
            case "speaking": return 0.85
            case "error": return 1.0
            default: return 0.4
        }
    }

    property real pulseSpeed: {
        switch (state) {
            case "listening": return 800
            case "thinking": return 1200
            case "speaking": return 600
            case "error": return 400
            default: return 3000
        }
    }

    Behavior on glowColor { ColorAnimation { duration: 600 } }
    Behavior on glowIntensity { NumberAnimation { duration: 600 } }

    // Pulse scale animation
    property real pulseScale: 1.0
    SequentialAnimation on pulseScale {
        loops: Animation.Infinite
        NumberAnimation {
            to: 1.06
            duration: root.pulseSpeed
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1.0
            duration: root.pulseSpeed
            easing.type: Easing.InOutSine
        }
    }

    // Inner rotation
    property real innerRotation: 0
    NumberAnimation on innerRotation {
        from: 0; to: 360
        duration: 20000
        loops: Animation.Infinite
    }

    // Outer glow layer
    Rectangle {
        id: outerGlow
        anchors.centerIn: parent
        width: parent.width * 1.6 * pulseScale
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 0

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.15 * root.glowIntensity) }
            GradientStop { position: 0.5; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.05 * root.glowIntensity) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Main sphere
    Canvas {
        id: sphereCanvas
        anchors.centerIn: parent
        width: parent.width * pulseScale
        height: width

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2;
            var cy = height / 2;
            var r = width / 2 - 2;

            ctx.clearRect(0, 0, width, height);

            // Main radial gradient
            var grad = ctx.createRadialGradient(cx * 0.85, cy * 0.75, r * 0.1, cx, cy, r);
            grad.addColorStop(0, Qt.rgba(root.glowColor.r * 0.8 + 0.2, root.glowColor.g * 0.8 + 0.2, root.glowColor.b * 0.8 + 0.2, 0.95));
            grad.addColorStop(0.4, Qt.rgba(root.glowColor.r * 0.5, root.glowColor.g * 0.5, root.glowColor.b * 0.5, 0.8));
            grad.addColorStop(0.7, Qt.rgba(root.glowColor.r * 0.2, root.glowColor.g * 0.2, root.glowColor.b * 0.2, 0.6));
            grad.addColorStop(1.0, Qt.rgba(root.glowColor.r * 0.1, root.glowColor.g * 0.1, root.glowColor.b * 0.1, 0.3));

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = grad;
            ctx.fill();

            // Inner highlight
            var hlGrad = ctx.createRadialGradient(cx * 0.7, cy * 0.6, 0, cx * 0.7, cy * 0.6, r * 0.5);
            hlGrad.addColorStop(0, Qt.rgba(1, 1, 1, 0.25));
            hlGrad.addColorStop(1, "transparent");
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = hlGrad;
            ctx.fill();

            // Edge glow
            var edgeGrad = ctx.createRadialGradient(cx, cy, r * 0.85, cx, cy, r);
            edgeGrad.addColorStop(0, "transparent");
            edgeGrad.addColorStop(1, Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.4 * root.glowIntensity));
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.fillStyle = edgeGrad;
            ctx.fill();
        }

        // Repaint when colors change
        Connections {
            target: root
            function onGlowColorChanged() { sphereCanvas.requestPaint() }
            function onGlowIntensityChanged() { sphereCanvas.requestPaint() }
            function onPulseScaleChanged() { sphereCanvas.requestPaint() }
        }
    }

    // Orbiting particles
    Repeater {
        model: 12
        Rectangle {
            id: orbitParticle
            property real angle: index * 30 + root.innerRotation
            property real orbitRadius: root.width * 0.38 + (index % 3) * 8
            property real particleSize: 2 + (index % 4)

            x: root.width / 2 + Math.cos(angle * Math.PI / 180) * orbitRadius - width / 2
            y: root.height / 2 + Math.sin(angle * Math.PI / 180) * orbitRadius - height / 2
            width: particleSize
            height: particleSize
            radius: particleSize / 2
            color: root.glowColor
            opacity: 0.3 + (index % 3) * 0.2

            Behavior on color { ColorAnimation { duration: 600 } }
        }
    }

    // Center dot
    Rectangle {
        anchors.centerIn: parent
        width: 6
        height: 6
        radius: 3
        color: "#ffffff"
        opacity: 0.8

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: root.pulseSpeed; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.8; duration: root.pulseSpeed; easing.type: Easing.InOutSine }
        }
    }
}
