import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root
    width: 300
    height: parent ? parent.height : 600
    edge: Qt.LeftEdge

    background: Rectangle {
        color: "#08081a"
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
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
                text: "CONVERSAS"
                color: "#8888aa"
                font.pixelSize: 11
                font.letterSpacing: 3
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                id: newChatBtn
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                background: Rectangle {
                    radius: 16
                    color: "#4466ff"
                }

                contentItem: Text {
                    text: "+"
                    color: "#ffffff"
                    font.pixelSize: 18
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    zyzz.newConversation()
                    root.close()
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // Conversation list
        ListView {
            id: convList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: zyzz.conversations

            delegate: ItemDelegate {
                width: convList.width
                height: 44

                background: Rectangle {
                    radius: 8
                    color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                }

                contentItem: RowLayout {
                    spacing: 8

                    Text {
                        text: model.title || "Nova conversa"
                        color: "#c0c0d0"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Button {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        visible: hovered

                        background: Rectangle {
                            radius: 12
                            color: Qt.rgba(1, 0.3, 0.3, 0.2)
                        }

                        contentItem: Text {
                            text: "\u2715"
                            color: "#ff6688"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: zyzz.deleteConversation(model.convId)
                    }
                }

                onClicked: {
                    zyzz.loadConversation(model.convId)
                    root.close()
                }
            }
        }
    }
}
