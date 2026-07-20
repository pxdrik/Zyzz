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
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.02)
        border.color: Qt.rgba(1, 1, 1, inputField.activeFocus ? 0.08 : 0.03)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 300 } }

        // ── Top row: prompt indicator + text input ──
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            spacing: 8

            // Terminal prompt symbol
            Text {
                text: "\u276F"
                color: inputField.activeFocus ? "#3b82f6" : "#475569"
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignVCenter
                opacity: 0.6

                Behavior on color { ColorAnimation { duration: 300 } }

                SequentialAnimation on opacity {
                    running: inputField.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.6; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            // Text field
            TextField {
                id: inputField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                placeholderText: "enter command..."
                placeholderTextColor: "#252540"
                color: "#c8cfe0"
                font.pixelSize: 14
                font.family: "Consolas"
                leftPadding: 4
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

            // Separator
            Rectangle {
                width: 1; height: 24
                Layout.alignment: Qt.AlignVCenter
                color: Qt.rgba(1, 1, 1, 0.04)
            }

            // Model badge
            Rectangle {
                Layout.preferredWidth: modelLabel.implicitWidth + 12
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: Qt.rgba(0.23, 0.51, 0.96, 0.06)
                border.color: Qt.rgba(0.23, 0.51, 0.96, 0.12)
                border.width: 1

                Text {
                    id: modelLabel
                    anchors.centerIn: parent
                    text: "GEMINI"
                    color: "#3b82f6"
                    font.pixelSize: 8
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                    font.family: "Consolas"
                    opacity: 0.7
                }
            }

            // Mic button
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: root.recording ? Qt.rgba(0.024, 0.714, 0.831, 0.1) : "transparent"
                border.color: root.recording ? Qt.rgba(0.024, 0.714, 0.831, 0.3) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uD83C\uDFA4"
                    font.pixelSize: 12
                    opacity: root.recording ? 1 : 0.35
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
                        running: root.recording; loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.OutCubic }
                        NumberAnimation { to: 0; duration: 800; easing.type: Easing.InCubic }
                    }
                    SequentialAnimation on scale {
                        running: root.recording; loops: Animation.Infinite
                        NumberAnimation { to: 1.3; duration: 800; easing.type: Easing.OutCubic }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.micToggled()
                }
            }

            // Send button
            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: inputField.text.trim() !== "" ? Qt.rgba(0.23, 0.51, 0.96, 0.1) : "transparent"
                border.color: inputField.text.trim() !== "" ? Qt.rgba(0.23, 0.51, 0.96, 0.2) : "transparent"
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
                    opacity: 0.8
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

        // ── Bottom accent glow ──
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.4
            height: 1

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(0.23, 0.51, 0.96, inputField.activeFocus ? 0.2 : 0.05) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
