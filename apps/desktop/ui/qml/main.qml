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
    color: "#03030a"

    // ── Background floating particles ──
    Repeater {
        model: 30
        Rectangle {
            id: bgParticle
            property real startX: Math.random() * root.width
            property real startY: Math.random() * root.height
            x: startX
            y: startY
            width: 2 + Math.random() * 3
            height: width
            radius: width / 2
            color: "#ffffff"
            opacity: 0.03 + Math.random() * 0.06

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation {
                    to: bgParticle.startY - 40 - Math.random() * 60
                    duration: 4000 + Math.random() * 6000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: bgParticle.startY
                    duration: 4000 + Math.random() * 6000
                    easing.type: Easing.InOutSine
                }
            }

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation {
                    to: bgParticle.startX - 20 - Math.random() * 30
                    duration: 5000 + Math.random() * 5000
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: bgParticle.startX + 20 + Math.random() * 30
                    duration: 5000 + Math.random() * 5000
                    easing.type: Easing.InOutSine
                }
            }
        }
    }

    // ── History drawer ──
    HistoryDrawer {
        id: historyDrawer
    }

    // ── Main layout ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // Top bar with menu button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 12

            Button {
                id: menuBtn
                text: "\u2630"
                font.pixelSize: 20
                background: Rectangle { color: "transparent" }
                contentItem: Text {
                    text: menuBtn.text
                    color: "#8888aa"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: historyDrawer.open()
            }

            Item { Layout.fillWidth: true }

            // Pipeline bar (visible when processing)
            PipelineBar {
                id: pipelineBar
                Layout.fillWidth: true
                Layout.maximumWidth: 600
                Layout.preferredHeight: 36
                visible: zyzz.pipelineVisible
            }

            Item { Layout.fillWidth: true }

            // State label
            Text {
                id: stateLabel
                text: {
                    switch (zyzz.state) {
                        case "listening": return "OUVINDO..."
                        case "thinking": return "PENSANDO..."
                        case "speaking": return "RESPONDENDO..."
                        case "error": return "ERRO"
                        default: return ""
                    }
                }
                color: {
                    switch (zyzz.state) {
                        case "listening": return "#00e5ff"
                        case "thinking": return "#aa88ff"
                        case "speaking": return "#00ff88"
                        case "error": return "#ff4466"
                        default: return "#666688"
                    }
                }
                font.pixelSize: 11
                font.letterSpacing: 3
                font.bold: true
                opacity: text === "" ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }

        // Spacer
        Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }

        // Core sphere — centered
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            Layout.alignment: Qt.AlignHCenter

            ZyzzCore {
                id: core
                anchors.centerIn: parent
                width: 220
                height: 220
                state: zyzz.state
            }
        }

        // Spacer
        Item { Layout.fillHeight: true; Layout.preferredHeight: 10 }

        // Response panel
        ResponsePanel {
            id: responsePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 80
            Layout.maximumHeight: 300
            responseText: zyzz.responseText
            visible: zyzz.responseText !== ""
        }

        // Spacer
        Item { Layout.fillHeight: true; Layout.preferredHeight: 10 }

        // Input bar
        InputBar {
            id: inputBar
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.maximumWidth: 700
            Layout.alignment: Qt.AlignHCenter
            recording: zyzz.recording
            onMessageSent: function(text) { zyzz.sendMessage(text) }
            onMicToggled: zyzz.toggleRecording()
        }

        // Bottom spacing
        Item { Layout.preferredHeight: 16 }
    }
}
