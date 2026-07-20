import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property bool recording: false

    signal messageSent(string text)
    signal micToggled()

    readonly property string mono: "Consolas"
    readonly property color cyan: "#06d6f0"

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(0.04, 0.06, 0.18, 0.7)
        border.color: Qt.rgba(0.024, 0.84, 0.94, inputField.activeFocus ? 0.2 : 0.08)
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 300 } }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 6; spacing: 4

            // ── Row 1: Text input ──
            RowLayout {
                Layout.fillWidth: true; spacing: 6

                // Mic
                Rectangle {
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
                    color: root.recording ? Qt.rgba(0.024,0.84,0.94,0.1) : "transparent"
                    border.color: root.recording ? Qt.rgba(0.024,0.84,0.94,0.3) : Qt.rgba(1,1,1,0.04); border.width: 1
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Text { anchors.centerIn: parent; text: "\uD83C\uDFA4"; font.pixelSize: 13; opacity: root.recording ? 1 : 0.35 }

                    Rectangle {
                        anchors.fill: parent; radius: parent.radius; color: "transparent"
                        border.color: root.cyan; border.width: 1; visible: root.recording; opacity: 0
                        SequentialAnimation on opacity { running: root.recording; loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.OutCubic }
                            NumberAnimation { to: 0; duration: 800; easing.type: Easing.InCubic }
                        }
                        SequentialAnimation on scale { running: root.recording; loops: Animation.Infinite
                            NumberAnimation { to: 1.3; duration: 800; easing.type: Easing.OutCubic }
                            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InCubic }
                        }
                    }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.micToggled() }
                }

                // Text field
                TextField {
                    id: inputField
                    Layout.fillWidth: true; Layout.preferredHeight: 36
                    placeholderText: "Ask anything, Zyzz is listening..."
                    placeholderTextColor: "#1a2a40"
                    color: "#c8d8f0"; font.pixelSize: 13; font.family: root.mono
                    leftPadding: 8; rightPadding: 8
                    selectionColor: Qt.rgba(0.024,0.84,0.94,0.3)
                    background: Rectangle { color: "transparent" }
                    Keys.onReturnPressed: { if (inputField.text.trim() !== "") { root.messageSent(inputField.text); inputField.text = "" } }
                }

                // Send
                Rectangle {
                    Layout.preferredWidth: 36; Layout.preferredHeight: 36; radius: 18
                    color: inputField.text.trim() !== "" ? Qt.rgba(0.024,0.84,0.94,0.15) : "transparent"
                    border.color: inputField.text.trim() !== "" ? Qt.rgba(0.024,0.84,0.94,0.3) : "transparent"; border.width: 1
                    opacity: inputField.text.trim() !== "" ? 1 : 0; scale: inputField.text.trim() !== "" ? 1 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 200 } }

                    Text { anchors.centerIn: parent; text: "\u25B6"; font.pixelSize: 14; color: root.cyan; opacity: 0.8 }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (inputField.text.trim() !== "") { root.messageSent(inputField.text); inputField.text = "" } }
                    }
                }
            }

            // ── Row 2: Controls ──
            RowLayout {
                Layout.fillWidth: true; Layout.leftMargin: 4; Layout.rightMargin: 4; spacing: 8

                // Model selector badge
                Rectangle {
                    Layout.preferredWidth: modelRow.implicitWidth + 16; Layout.preferredHeight: 22; radius: 6
                    color: Qt.rgba(0.024,0.84,0.94,0.05); border.color: Qt.rgba(0.024,0.84,0.94,0.12); border.width: 1

                    Row { id: modelRow; anchors.centerIn: parent; spacing: 4
                        Text { text: "\u2B24"; font.pixelSize: 5; color: "#10b981"; anchors.verticalCenter: parent.verticalCenter; opacity: 0.6 }
                        Text { text: "GEMINI-2.0"; color: root.cyan; font.pixelSize: 8; font.letterSpacing: 1; font.weight: Font.Medium; font.family: root.mono; opacity: 0.6 }
                        Text { text: "\u25BE"; color: "#4a6a80"; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter; opacity: 0.4 }
                    }
                }

                // Deep Think
                Rectangle {
                    Layout.preferredWidth: dtLbl.implicitWidth + 16; Layout.preferredHeight: 22; radius: 6
                    color: dtMouse.containsMouse ? Qt.rgba(0.55,0.36,0.96,0.08) : Qt.rgba(1,1,1,0.02)
                    border.color: dtMouse.containsMouse ? Qt.rgba(0.55,0.36,0.96,0.15) : Qt.rgba(1,1,1,0.04); border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text { id: dtLbl; anchors.centerIn: parent; text: "\uD83E\uDDE0 DEEP THINK"; color: "#8b5cf6"; font.pixelSize: 8; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    MouseArea { id: dtMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }

                // Web Search
                Rectangle {
                    Layout.preferredWidth: wsLbl.implicitWidth + 16; Layout.preferredHeight: 22; radius: 6
                    color: wsMouse.containsMouse ? Qt.rgba(0.024,0.84,0.94,0.06) : Qt.rgba(1,1,1,0.02)
                    border.color: wsMouse.containsMouse ? Qt.rgba(0.024,0.84,0.94,0.12) : Qt.rgba(1,1,1,0.04); border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Text { id: wsLbl; anchors.centerIn: parent; text: "\uD83C\uDF10 WEB SEARCH"; color: root.cyan; font.pixelSize: 8; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    MouseArea { id: wsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }

                Item { Layout.fillWidth: true }

                // Voice status
                Text {
                    text: root.recording ? "VOICE RECORDING" : "VOICE READY"
                    color: root.recording ? root.cyan : "#3a5a70"
                    font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}
