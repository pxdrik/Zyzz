import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "ZYZZ"
    color: "#05050f"

    // ── Ambient radial glow behind AI Presence ──
    Canvas {
        id: ambientGlow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        width: 700
        height: 700
        opacity: 0.35

        property color glowColor: {
            switch (zyzz.state) {
                case "listening": return "#06b6d4"
                case "thinking": return "#8b5cf6"
                case "speaking": return "#10b981"
                case "error": return "#ef4444"
                default: return "#3b82f6"
            }
        }

        Behavior on glowColor { ColorAnimation { duration: 1200; easing.type: Easing.InOutQuad } }

        onGlowColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            var cx = width / 2, cy = height / 2;
            ctx.clearRect(0, 0, width, height);
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, cx);
            g.addColorStop(0, Qt.rgba(glowColor.r, glowColor.g, glowColor.b, 0.12));
            g.addColorStop(0.3, Qt.rgba(glowColor.r, glowColor.g, glowColor.b, 0.04));
            g.addColorStop(0.7, Qt.rgba(glowColor.r, glowColor.g, glowColor.b, 0.01));
            g.addColorStop(1, "transparent");
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
    }

    // ── Atmospheric particles ──
    Repeater {
        model: 45
        Rectangle {
            id: atmParticle
            property real baseX: Math.random() * root.width
            property real baseY: Math.random() * root.height
            property real sz: 1 + Math.random() * 1.5
            property real baseOpacity: 0.015 + Math.random() * 0.04
            property bool isTinted: Math.random() > 0.7

            x: baseX
            y: baseY
            width: sz
            height: sz
            radius: sz / 2
            color: isTinted ? (Math.random() > 0.5 ? "#3b82f6" : "#8b5cf6") : "#e2e8f0"
            opacity: baseOpacity

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    to: atmParticle.baseY - 30 - Math.random() * 80
                    duration: 8000 + Math.random() * 12000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: atmParticle.baseY + 10 + Math.random() * 20
                    duration: 8000 + Math.random() * 12000
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation {
                    to: atmParticle.baseX - 15 - Math.random() * 25
                    duration: 10000 + Math.random() * 15000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: atmParticle.baseX + 15 + Math.random() * 25
                    duration: 10000 + Math.random() * 15000
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: atmParticle.baseOpacity * 0.2
                    duration: 6000 + Math.random() * 8000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: atmParticle.baseOpacity
                    duration: 6000 + Math.random() * 8000
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // ── History panel ──
    HistoryDrawer {
        id: historyDrawer
    }

    // ── Main content ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 0

        // ── Top bar ──
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 16

            // Menu
            Rectangle {
                width: 28; height: 28
                color: "transparent"
                opacity: 0.4

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: 3
                        Rectangle { width: 14; height: 1.5; radius: 1; color: "#e2e8f0" }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: historyDrawer.open()
                    onContainsMouseChanged: parent.opacity = containsMouse ? 0.7 : 0.4
                }

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Item { Layout.fillWidth: true }

            // Status
            Row {
                spacing: 8
                opacity: zyzz.state !== "idle" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                Rectangle {
                    width: 5; height: 5; radius: 2.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        switch (zyzz.state) {
                            case "listening": return "#06b6d4"
                            case "thinking": return "#8b5cf6"
                            case "speaking": return "#10b981"
                            case "error": return "#ef4444"
                            default: return "#64748b"
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 600 } }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: {
                        switch (zyzz.state) {
                            case "listening": return "LISTENING"
                            case "thinking": return "PROCESSING"
                            case "speaking": return "STREAMING"
                            case "error": return "ERROR"
                            default: return ""
                        }
                    }
                    color: {
                        switch (zyzz.state) {
                            case "listening": return "#06b6d4"
                            case "thinking": return "#8b5cf6"
                            case "speaking": return "#10b981"
                            case "error": return "#ef4444"
                            default: return "#64748b"
                        }
                    }
                    font.pixelSize: 10
                    font.letterSpacing: 3
                    font.weight: Font.Medium
                    Behavior on color { ColorAnimation { duration: 600 } }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Pipeline ──
        PipelineBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 16
            visible: zyzz.pipelineVisible
            opacity: zyzz.pipelineVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }

        // ── AI Presence ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            Layout.alignment: Qt.AlignHCenter

            ZyzzCore {
                id: aiPresence
                anchors.centerIn: parent
                width: 300
                height: 300
                aiState: zyzz.state
            }
        }

        Item { Layout.preferredHeight: 20 }

        // ── Response ──
        ResponsePanel {
            id: responsePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 40
            Layout.maximumHeight: 260
            Layout.maximumWidth: 720
            Layout.alignment: Qt.AlignHCenter
            responseText: zyzz.responseText
            aiState: zyzz.state
            visible: zyzz.responseText !== ""
            opacity: zyzz.responseText !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }

        Item { Layout.fillHeight: true }

        // ── Input ──
        InputBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            Layout.maximumWidth: 640
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            recording: zyzz.recording
            onMessageSent: function(text) { zyzz.sendMessage(text) }
            onMicToggled: zyzz.toggleRecording()
        }
    }
}
