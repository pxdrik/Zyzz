import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool recording: false

    signal messageSent(string text)
    signal micToggled()

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Qt.rgba(0, 0.94, 1, 0.02)
        border.color: Qt.rgba(0, 0.94, 1, recording ? 0.4 : 0.1)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 300 } }

        // Bottom glow line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.6
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0.94, 1, recording ? 0.4 : 0.12) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 8

            // Mic button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: root.recording ? Qt.rgba(0, 0.94, 1, 0.15) : "transparent"
                border.color: root.recording ? "#00f0ff" : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uD83C\uDFA4"
                    font.pixelSize: 14
                    color: root.recording ? "#00f0ff" : "#555577"
                }

                // Recording pulse
                SequentialAnimation on opacity {
                    running: root.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 400 }
                    NumberAnimation { to: 1.0; duration: 400 }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.micToggled()
                }
            }

            // Text input
            TextField {
                id: inputField
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                placeholderText: "type or speak..."
                placeholderTextColor: "#333355"
                color: "#c0c8e0"
                font.pixelSize: 13
                font.family: "Consolas"
                leftPadding: 8
                rightPadding: 8
                selectionColor: Qt.rgba(0, 0.94, 1, 0.3)

                background: Rectangle { color: "transparent" }

                Keys.onReturnPressed: {
                    if (inputField.text.trim() !== "") {
                        root.messageSent(inputField.text)
                        inputField.text = ""
                    }
                }
            }

            // Send button
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: inputField.text.trim() !== "" ? Qt.rgba(0, 0.94, 1, 0.1) : "transparent"
                border.color: inputField.text.trim() !== "" ? Qt.rgba(0, 0.94, 1, 0.3) : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: "\u27A4"
                    font.pixelSize: 14
                    color: inputField.text.trim() !== "" ? "#00f0ff" : "#333355"
                    Behavior on color { ColorAnimation { duration: 200 } }
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
