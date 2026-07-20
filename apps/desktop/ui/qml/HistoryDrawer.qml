import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root
    width: 280
    height: parent ? parent.height : 600
    edge: Qt.LeftEdge

    background: Rectangle {
        color: "#08081a"

        // Right edge accent
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(0.23, 0.51, 0.96, 0.1) }
                GradientStop { position: 0.7; color: Qt.rgba(0.23, 0.51, 0.96, 0.1) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "History"
                color: "#e2e8f0"
                font.pixelSize: 14
                font.weight: Font.Medium
                opacity: 0.6
                Layout.fillWidth: true
            }

            Rectangle {
                width: 28; height: 28
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "#e2e8f0"
                    font.pixelSize: 15
                    opacity: 0.5
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: { zyzz.newConversation(); root.close() }
                    onContainsMouseChanged: parent.border.color = containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                }
            }
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.04)
        }

        // ── Conversation list ──
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
                radius: 8
                color: convMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"

                property bool hovered: convMouse.containsMouse || delMouse.containsMouse

                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: convMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { zyzz.loadConversation(model.convId); root.close() }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8
                    z: 1

                    Text {
                        text: model.title || "New conversation"
                        color: "#e2e8f0"
                        font.pixelSize: 13
                        opacity: 0.55
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 22; height: 22
                        radius: 11
                        color: delMouse.containsMouse ? Qt.rgba(0.93, 0.27, 0.27, 0.1) : "transparent"
                        visible: convItem.hovered
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: "\u00D7"
                            color: "#ef4444"
                            font.pixelSize: 14
                            opacity: 0.5
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
    }
}
