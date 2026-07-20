import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real travelProgress: 0
    NumberAnimation on travelProgress {
        from: 0; to: 1
        duration: 1500
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: zyzz.pipeline

            delegate: Row {
                spacing: 0

                // Connector
                Item {
                    visible: index > 0
                    width: 32
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    // Line
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Qt.rgba(0, 0.94, 1, 0.1)
                    }

                    // Traveling dot
                    Rectangle {
                        width: 4; height: 4; radius: 2
                        color: "#00f0ff"
                        opacity: 0.8
                        y: parent.height / 2 - 2
                        x: root.travelProgress * (parent.width - 4)
                    }
                }

                // Node
                Rectangle {
                    width: nodeLabel.implicitWidth + 18
                    height: 24
                    radius: 2
                    color: model.active ? Qt.rgba(0, 0.94, 1, 0.06) : "transparent"
                    border.color: model.active ? Qt.rgba(0, 0.94, 1, 0.25) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1

                    Text {
                        id: nodeLabel
                        anchors.centerIn: parent
                        text: model.name
                        color: model.active ? "#00f0ff" : "#334155"
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        font.family: "Consolas"
                        font.bold: true
                    }

                    SequentialAnimation on opacity {
                        running: model.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }
            }
        }
    }
}
