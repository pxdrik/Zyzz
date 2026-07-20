import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root
    width: 280
    height: parent ? parent.height : 600
    edge: Qt.LeftEdge

    background: Rectangle {
        color: "#020208"
        border.color: Qt.rgba(0, 0.94, 1, 0.08)
        border.width: 1

        // Right edge glow
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(0, 0.94, 1, 0.15) }
                GradientStop { position: 0.7; color: Qt.rgba(0, 0.94, 1, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "// HISTORY"
                color: "#00f0ff"
                opacity: 0.4
                font.pixelSize: 10
                font.letterSpacing: 3
                font.family: "Consolas"
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28; height: 28
                radius: 3
                color: Qt.rgba(0, 0.94, 1, 0.08)
                border.color: Qt.rgba(0, 0.94, 1, 0.2)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#00f0ff"
                    font.pixelSize: 16
                    font.family: "Consolas"
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zyzz.newConversation()
                        root.close()
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(0, 0.94, 1, 0.06)
        }

        // List
        ListView {
            id: convList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: zyzz.conversations

            delegate: Rectangle {
                id: convItem
                width: convList.width
                height: 40
                radius: 3

                property bool hovered: convMouse.containsMouse || delMouse.containsMouse

                color: hovered ? Qt.rgba(0, 0.94, 1, 0.04) : "transparent"
                border.color: hovered ? Qt.rgba(0, 0.94, 1, 0.08) : "transparent"
                border.width: 1

                MouseArea {
                    id: convMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        zyzz.loadConversation(model.convId)
                        root.close()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6
                    z: 1

                    // Dot
                    Rectangle {
                        width: 4; height: 4; radius: 2
                        color: "#00f0ff"
                        opacity: 0.3
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: model.title || "new conversation"
                        color: "#8090b0"
                        font.pixelSize: 12
                        font.family: "Consolas"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Delete
                    Rectangle {
                        width: 22; height: 22
                        radius: 2
                        color: delMouse.containsMouse ? Qt.rgba(1, 0.2, 0.2, 0.1) : "transparent"
                        visible: convItem.hovered
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "\u2715"
                            color: "#ef4444"
                            font.pixelSize: 10
                            opacity: 0.7
                        }

                        MouseArea {
                            id: delMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: zyzz.deleteConversation(model.convId)
                        }
                    }
                }
            }
        }

        // Footer
        Text {
            Layout.fillWidth: true
            text: "ZYZZ v1.0"
            color: "#222244"
            font.pixelSize: 9
            font.letterSpacing: 2
            font.family: "Consolas"
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
