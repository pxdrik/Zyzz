import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string responseText: ""
    property string aiState: "idle"

    property color accentColor: {
        switch (aiState) {
            case "listening": return "#06b6d4"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            default: return "#3b82f6"
        }
    }

    Behavior on accentColor { ColorAnimation { duration: 800 } }

    // ── Entrance animation ──
    property real slideOffset: 8
    property real panelOpacity: 0

    Component.onCompleted: {
        slideOffset = 0
        panelOpacity = 1
    }

    Behavior on slideOffset { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    Behavior on panelOpacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    transform: Translate { y: root.slideOffset }
    opacity: panelOpacity

    // ── Glass panel ──
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.02)
        border.color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1

        // ── Left accent line ──
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            width: 2
            radius: 1

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) }
                GradientStop { position: 0.8; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // ── Streaming indicator ──
        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 14
            spacing: 4
            opacity: root.aiState === "speaking" ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Repeater {
                model: 3
                Rectangle {
                    width: 3; height: 3; radius: 1.5
                    color: root.accentColor

                    SequentialAnimation on opacity {
                        running: root.aiState === "speaking"
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 200 }
                        NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        // ── Response text ──
        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            contentHeight: responseLabel.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Text {
                id: responseLabel
                width: flickable.width
                text: root.responseText
                color: "#c8cfe0"
                font.pixelSize: 14
                font.family: "Segoe UI"
                lineHeight: 1.65
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }

            onContentHeightChanged: {
                if (contentHeight > height) {
                    contentY = contentHeight - height
                }
            }
        }
    }
}
