import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Traveling light animation
    property real travelProgress: 0
    NumberAnimation on travelProgress {
        from: 0; to: 1
        duration: 2000
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

                // Connector line (not before the first node)
                Rectangle {
                    visible: index > 0
                    width: 24
                    height: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, 0.1)

                    // Traveling light dot
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        y: -2
                        color: "#4466ff"
                        opacity: 0.8
                        x: root.travelProgress * (parent.width - 6)
                    }
                }

                // Node capsule
                Rectangle {
                    width: nodeText.implicitWidth + 20
                    height: 28
                    radius: 14
                    color: model.active ? Qt.rgba(0.27, 0.4, 1, 0.15) : Qt.rgba(1, 1, 1, 0.04)
                    border.color: model.active ? Qt.rgba(0.27, 0.4, 1, 0.4) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Text {
                        id: nodeText
                        anchors.centerIn: parent
                        text: model.name
                        color: model.active ? "#88aaff" : "#666688"
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.bold: true
                    }

                    // Pulse when active
                    SequentialAnimation on opacity {
                        running: model.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.7; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }
}
