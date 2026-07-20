import QtQuick
import QtQuick.Layouts

Item {
    id: root

    RowLayout {
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: zyzz.pipeline

            delegate: Row {
                spacing: 0

                // Connector arrow
                Text {
                    visible: index > 0
                    text: " \u2192 "
                    color: "#64748b"
                    font.pixelSize: 10
                    opacity: 0.4
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Node label
                Text {
                    text: model.name
                    color: model.active ? "#e2e8f0" : "#64748b"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    font.weight: model.active ? Font.Medium : Font.Normal
                    opacity: model.active ? 0.7 : 0.3
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }
        }
    }
}
