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
    color: "#000000"

    // ── Animated grid background ──
    Canvas {
        id: gridBg
        anchors.fill: parent
        opacity: 0.06

        property real gridOffset: 0
        NumberAnimation on gridOffset {
            from: 0; to: 40
            duration: 8000
            loops: Animation.Infinite
        }

        onGridOffsetChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = "#00f0ff";
            ctx.lineWidth = 0.5;

            var spacing = 40;
            for (var x = -spacing + (gridOffset % spacing); x < width + spacing; x += spacing) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
                ctx.stroke();
            }
            for (var y = -spacing + (gridOffset % spacing); y < height + spacing; y += spacing) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
        }
    }

    // ── Horizontal scan line ──
    Rectangle {
        id: scanLine
        width: parent.width
        height: 2
        color: "#00f0ff"
        opacity: 0.03
        y: 0

        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: root.height; duration: 6000; easing.type: Easing.Linear }
            NumberAnimation { to: 0; duration: 0 }
        }
    }

    // ── Floating particles ──
    Repeater {
        model: 50
        Rectangle {
            id: particle
            property real startX: Math.random() * root.width
            property real startY: Math.random() * root.height
            property real size: 1 + Math.random() * 2
            x: startX
            y: startY
            width: size
            height: size
            radius: size / 2
            color: Math.random() > 0.5 ? "#00f0ff" : "#a855f7"
            opacity: 0.08 + Math.random() * 0.15

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    to: particle.startY - 60 - Math.random() * 100
                    duration: 5000 + Math.random() * 8000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: particle.startY
                    duration: 5000 + Math.random() * 8000
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.02
                    duration: 3000 + Math.random() * 4000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0.08 + Math.random() * 0.15
                    duration: 3000 + Math.random() * 4000
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // ── HUD corner brackets ──
    // Top-left
    Canvas {
        width: 60; height: 60; x: 12; y: 12; opacity: 0.15
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#00f0ff"; ctx.lineWidth = 1.5;
            ctx.beginPath(); ctx.moveTo(0, 20); ctx.lineTo(0, 0); ctx.lineTo(20, 0); ctx.stroke();
        }
    }
    // Top-right
    Canvas {
        width: 60; height: 60; x: root.width - 72; y: 12; opacity: 0.15
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#00f0ff"; ctx.lineWidth = 1.5;
            ctx.beginPath(); ctx.moveTo(40, 0); ctx.lineTo(60, 0); ctx.lineTo(60, 20); ctx.stroke();
        }
    }
    // Bottom-left
    Canvas {
        width: 60; height: 60; x: 12; y: root.height - 72; opacity: 0.15
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#00f0ff"; ctx.lineWidth = 1.5;
            ctx.beginPath(); ctx.moveTo(0, 40); ctx.lineTo(0, 60); ctx.lineTo(20, 60); ctx.stroke();
        }
    }
    // Bottom-right
    Canvas {
        width: 60; height: 60; x: root.width - 72; y: root.height - 72; opacity: 0.15
        onPaint: {
            var ctx = getContext("2d");
            ctx.strokeStyle = "#00f0ff"; ctx.lineWidth = 1.5;
            ctx.beginPath(); ctx.moveTo(40, 60); ctx.lineTo(60, 60); ctx.lineTo(60, 40); ctx.stroke();
        }
    }

    // ── History drawer ──
    HistoryDrawer {
        id: historyDrawer
    }

    // ── Main content ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 0

        // ── Top HUD bar ──
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 16

            // Menu button
            Rectangle {
                width: 36; height: 36
                color: "transparent"
                border.color: Qt.rgba(0, 0.94, 1, 0.2)
                border.width: 1
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: "\u2630"
                    color: "#00f0ff"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: historyDrawer.open()
                }
            }

            // System title
            Text {
                text: "Z Y Z Z"
                color: "#00f0ff"
                font.pixelSize: 13
                font.letterSpacing: 6
                font.family: "Consolas"
                font.bold: true
                opacity: 0.7
            }

            Item { Layout.fillWidth: true }

            // Pipeline bar
            PipelineBar {
                id: pipelineBar
                Layout.fillWidth: true
                Layout.maximumWidth: 500
                Layout.preferredHeight: 32
                visible: zyzz.pipelineVisible
            }

            Item { Layout.fillWidth: true }

            // Status indicator
            Row {
                spacing: 8
                visible: zyzz.state !== "idle"

                Rectangle {
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        switch (zyzz.state) {
                            case "listening": return "#00f0ff"
                            case "thinking": return "#a855f7"
                            case "speaking": return "#22c55e"
                            case "error": return "#ef4444"
                            default: return "#334155"
                        }
                    }

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
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
                            case "listening": return "#00f0ff"
                            case "thinking": return "#a855f7"
                            case "speaking": return "#22c55e"
                            case "error": return "#ef4444"
                            default: return "#334155"
                        }
                    }
                    font.pixelSize: 10
                    font.letterSpacing: 3
                    font.family: "Consolas"
                    font.bold: true
                }
            }
        }

        // ── Separator line ──
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(0, 0.94, 1, 0.15) }
                GradientStop { position: 0.7; color: Qt.rgba(0, 0.94, 1, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Core sphere ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            Layout.alignment: Qt.AlignHCenter

            ZyzzCore {
                id: core
                anchors.centerIn: parent
                width: 280
                height: 280
                state: zyzz.state
            }
        }

        Item { Layout.preferredHeight: 12 }

        // ── Response panel ──
        ResponsePanel {
            id: responsePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 60
            Layout.maximumHeight: 280
            Layout.maximumWidth: 800
            Layout.alignment: Qt.AlignHCenter
            responseText: zyzz.responseText
            visible: zyzz.responseText !== ""
        }

        Item { Layout.fillHeight: true }

        // ── Separator line ──
        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(0, 0.94, 1, 0.08) }
                GradientStop { position: 0.7; color: Qt.rgba(0, 0.94, 1, 0.08) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Input bar ──
        InputBar {
            id: inputBar
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.maximumWidth: 680
            Layout.alignment: Qt.AlignHCenter
            recording: zyzz.recording
            onMessageSent: function(text) { zyzz.sendMessage(text) }
            onMicToggled: zyzz.toggleRecording()
        }

        Item { Layout.preferredHeight: 20 }
    }
}
