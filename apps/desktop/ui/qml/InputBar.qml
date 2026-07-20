import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool recording: false

    signal messageSent(string text)
    signal micToggled()

    Rectangle {
        id: glassBar
        anchors.fill: parent
        radius: 28
        color: Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Mic button
            Button {
                id: micBtn
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter

                background: Rectangle {
                    radius: 20
                    color: root.recording ? "#00e5ff" : Qt.rgba(1, 1, 1, 0.06)
                    border.color: root.recording ? "#00e5ff" : Qt.rgba(1, 1, 1, 0.1)
                    border.width: 1

                    SequentialAnimation on opacity {
                        running: root.recording
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.5; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }

                contentItem: Text {
                    text: "\uD83C\uDFA4"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: root.recording ? "#03030a" : "#8888aa"
                }

                onClicked: root.micToggled()
            }

            // Text input
            TextField {
                id: inputField
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                placeholderText: "Fale ou digite..."
                placeholderTextColor: "#555566"
                color: "#e0e0ee"
                font.pixelSize: 14
                leftPadding: 12
                rightPadding: 12

                background: Rectangle {
                    color: "transparent"
                }

                Keys.onReturnPressed: {
                    if (inputField.text.trim() !== "") {
                        root.messageSent(inputField.text)
                        inputField.text = ""
                    }
                }
            }

            // Send button
            Button {
                id: sendBtn
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                enabled: inputField.text.trim() !== ""

                background: Rectangle {
                    radius: 20
                    color: sendBtn.enabled ? "#4466ff" : Qt.rgba(1, 1, 1, 0.04)
                    border.color: sendBtn.enabled ? "#4466ff" : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                contentItem: Text {
                    text: "\u279C"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: sendBtn.enabled ? "#ffffff" : "#555566"
                }

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
