import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string responseText: ""

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Qt.rgba(0, 0.94, 1, 0.015)
        border.color: Qt.rgba(0, 0.94, 1, 0.06)
        border.width: 1

        // Top accent line
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.4
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0.94, 1, 0.2) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Header label
        Text {
            id: headerLabel
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 14
            text: "// OUTPUT"
            color: "#00f0ff"
            opacity: 0.25
            font.pixelSize: 9
            font.letterSpacing: 2
            font.family: "Consolas"
            font.bold: true
        }

        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.topMargin: 32
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 12
            contentHeight: responseLabel.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Text {
                id: responseLabel
                width: flickable.width
                text: root.responseText
                color: "#b0b8d0"
                font.pixelSize: 13
                font.family: "Consolas"
                lineHeight: 1.6
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }

            onContentHeightChanged: {
                if (contentHeight > height) {
                    contentY = contentHeight - height
                }
            }
        }

        // Cursor blink at end of text
        Rectangle {
            visible: root.responseText !== ""
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 14
            width: 7
            height: 14
            color: "#00f0ff"

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 500 }
                NumberAnimation { to: 0.6; duration: 500 }
            }
        }
    }

    // Fade in
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    Component.onCompleted: opacity = 1
}
