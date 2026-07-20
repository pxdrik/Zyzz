import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool recording: false

    signal messageSent(string text)
    signal micToggled()

    // ── Glass container ──
    Rectangle {
        anchors.fill: parent
        radius: 26
        color: Qt.rgba(1, 1, 1, 0.025)
        border.color: Qt.rgba(1, 1, 1, inputField.activeFocus ? 0.1 : 0.04)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 300 } }

        // ── Bottom accent glow ──
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.5
            height: 1
            opacity: inputField.activeFocus ? 1 : 0.5

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(0.23, 0.51, 0.96, inputField.activeFocus ? 0.25 : 0.08) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 4

            // ── Mic button ──
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignVCenter
                radius: 19
                color: root.recording ? Qt.rgba(0.024, 0.714, 0.831, 0.12) : "transparent"
                border.color: root.recording ? Qt.rgba(0.024, 0.714, 0.831, 0.35) : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uD83C\uDFA4"
                    font.pixelSize: 13
                    opacity: root.recording ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                // Recording pulse
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: "#06b6d4"
                    border.width: 1
                    visible: root.recording
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: root.recording
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 800; easing.type: Easing.OutCubic }
                        NumberAnimation { to: 0; duration: 800; easing.type: Easing.InCubic }
                    }

                    SequentialAnimation on scale {
                        running: root.recording
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.4; duration: 800; easing.type: Easing.OutCubic }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.micToggled()
                }
            }

            // ── Text input ──
            TextField {
                id: inputField
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                placeholderText: "ask anything..."
                placeholderTextColor: "#3a3a5c"
                color: "#e2e8f0"
                font.pixelSize: 14
                leftPadding: 8
                rightPadding: 8
                selectionColor: Qt.rgba(0.23, 0.51, 0.96, 0.3)

                background: Rectangle { color: "transparent" }

                Keys.onReturnPressed: {
                    if (inputField.text.trim() !== "") {
                        root.messageSent(inputField.text)
                        inputField.text = ""
                    }
                }
            }

            // ── Send button (appears when text entered) ──
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 17
                color: inputField.text.trim() !== "" ? Qt.rgba(0.23, 0.51, 0.96, 0.15) : "transparent"
                border.color: inputField.text.trim() !== "" ? Qt.rgba(0.23, 0.51, 0.96, 0.3) : "transparent"
                border.width: 1
                opacity: inputField.text.trim() !== "" ? 1 : 0
                scale: inputField.text.trim() !== "" ? 1 : 0.8

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u2191"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: "#3b82f6"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (inputField.text.trim() !== "") {
                            root.messageSent(inputField.text)
                            inputField.text = ""
                        }
                    }
                }
            }
        }
    }
}
