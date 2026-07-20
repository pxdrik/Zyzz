import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string responseText: ""

    Rectangle {
        id: glassPanel
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.03)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: 20
            contentHeight: responseLabel.implicitHeight
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Text {
                id: responseLabel
                width: flickable.width
                text: root.responseText
                color: "#d0d0e0"
                font.pixelSize: 14
                font.family: "Segoe UI"
                lineHeight: 1.5
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }

            // Auto-scroll to bottom when text changes
            onContentHeightChanged: {
                if (contentHeight > height) {
                    contentY = contentHeight - height
                }
            }
        }

        // Fade-in animation
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Component.onCompleted: opacity = 1
    }
}
