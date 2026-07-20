import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "ZYZZ"
    color: "#020208"

    // ── Global state color ──
    property color stateColor: {
        switch (zyzz.state) {
            case "listening": return "#06b6d4"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            case "error": return "#ef4444"
            default: return "#3b82f6"
        }
    }
    Behavior on stateColor { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

    // ── Clock property ──
    property string clockText: ""
    property string dateText: ""
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.clockText = Qt.formatTime(d, "HH:mm:ss")
            root.dateText = Qt.formatDate(d, "dd MMM yyyy").toUpperCase()
        }
    }

    // ── Uptime ──
    property int uptimeSeconds: 0
    property string uptimeText: "00:00:00"
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            root.uptimeSeconds++
            var h = Math.floor(root.uptimeSeconds / 3600)
            var m = Math.floor((root.uptimeSeconds % 3600) / 60)
            var s = root.uptimeSeconds % 60
            root.uptimeText = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
        }
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 0 — Background: Polar grid + Nebula
    // ══════════════════════════════════════════════════════════

    // ── Polar grid ──
    Canvas {
        id: polarGrid
        anchors.fill: parent
        opacity: 0.04

        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2
            var maxR = Math.sqrt(cx * cx + cy * cy)
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = "#3b82f6"
            ctx.lineWidth = 0.5

            // Concentric circles
            for (var i = 1; i <= 12; i++) {
                var r = (maxR / 12) * i
                ctx.globalAlpha = 0.3 + (i % 3 === 0 ? 0.3 : 0)
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.stroke()
            }

            // Radial lines
            ctx.globalAlpha = 0.2
            for (var j = 0; j < 24; j++) {
                var angle = (j * Math.PI * 2) / 24
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + Math.cos(angle) * maxR, cy + Math.sin(angle) * maxR)
                ctx.stroke()
            }
        }

        Component.onCompleted: requestPaint()
    }

    // ── Nebula blob 1 ──
    Canvas {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -200
        anchors.verticalCenterOffset: -150
        width: 600; height: 600
        opacity: 0.025

        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2
            ctx.clearRect(0, 0, width, height)
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, 300)
            g.addColorStop(0, Qt.rgba(0.23, 0.36, 0.96, 0.5))
            g.addColorStop(0.5, Qt.rgba(0.55, 0.36, 0.96, 0.2))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }
        Component.onCompleted: requestPaint()
    }

    // ── Nebula blob 2 ──
    Canvas {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 250
        anchors.verticalCenterOffset: 100
        width: 500; height: 500
        opacity: 0.02

        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2
            ctx.clearRect(0, 0, width, height)
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, 250)
            g.addColorStop(0, Qt.rgba(0.024, 0.714, 0.831, 0.4))
            g.addColorStop(0.6, Qt.rgba(0.06, 0.35, 0.55, 0.15))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }
        Component.onCompleted: requestPaint()
    }

    // ── Ambient radial glow behind core ──
    Canvas {
        id: ambientGlow
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: 700; height: 700
        opacity: 0.4

        onPaint: {
            var ctx = getContext("2d")
            var cx = width / 2, cy = height / 2
            ctx.clearRect(0, 0, width, height)
            var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, cx)
            g.addColorStop(0, Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.15))
            g.addColorStop(0.3, Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.05))
            g.addColorStop(0.7, Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.01))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g
            ctx.fillRect(0, 0, width, height)
        }

        Connections {
            target: root
            function onStateColorChanged() { ambientGlow.requestPaint() }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 1 — Atmospheric particles (60 particles)
    // ══════════════════════════════════════════════════════════

    Repeater {
        model: 60
        Rectangle {
            id: atmP
            property real baseX: Math.random() * root.width
            property real baseY: Math.random() * root.height
            property real sz: 0.8 + Math.random() * 1.8
            property real baseOp: 0.01 + Math.random() * 0.04
            property bool tinted: Math.random() > 0.65

            x: baseX; y: baseY
            width: sz; height: sz; radius: sz / 2
            color: tinted ? (Math.random() > 0.5 ? "#3b82f6" : "#8b5cf6") : "#e2e8f0"
            opacity: baseOp

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: atmP.baseY - 40 - Math.random() * 100; duration: 8000 + Math.random() * 14000; easing.type: Easing.InOutSine }
                NumberAnimation { to: atmP.baseY + 15 + Math.random() * 30; duration: 8000 + Math.random() * 14000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: atmP.baseX - 20 - Math.random() * 30; duration: 12000 + Math.random() * 16000; easing.type: Easing.InOutSine }
                NumberAnimation { to: atmP.baseX + 20 + Math.random() * 30; duration: 12000 + Math.random() * 16000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: atmP.baseOp * 0.15; duration: 5000 + Math.random() * 9000; easing.type: Easing.InOutSine }
                NumberAnimation { to: atmP.baseOp; duration: 5000 + Math.random() * 9000; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── Data stream lines (vertical flowing lines) ──
    Repeater {
        model: 8
        Rectangle {
            id: dataLine
            property real startX: 60 + Math.random() * (root.width - 120)
            x: startX; y: -height
            width: 1; height: 30 + Math.random() * 60
            radius: 0.5
            color: root.stateColor
            opacity: 0.03 + Math.random() * 0.04

            Behavior on color { ColorAnimation { duration: 1000 } }

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { from: -dataLine.height; to: root.height + 20; duration: 6000 + Math.random() * 10000; easing.type: Easing.Linear }
                PauseAnimation { duration: Math.random() * 4000 }
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 2 — Mouse proximity glow
    // ══════════════════════════════════════════════════════════

    MouseArea {
        id: mouseTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        property real mx: mouseX
        property real my: mouseY
    }

    Rectangle {
        x: mouseTracker.mx - 75
        y: mouseTracker.my - 75
        width: 150; height: 150; radius: 75
        visible: mouseTracker.containsMouse
        color: "transparent"

        Canvas {
            anchors.fill: parent
            opacity: 0.06
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var g = ctx.createRadialGradient(75, 75, 0, 75, 75, 75)
                g.addColorStop(0, Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.5))
                g.addColorStop(1, "transparent")
                ctx.fillStyle = g
                ctx.fillRect(0, 0, width, height)
            }

            Connections {
                target: root
                function onStateColorChanged() { parent.children[0].requestPaint() }
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 3 — Left nav bar (holographic icons)
    // ══════════════════════════════════════════════════════════

    Rectangle {
        id: navBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 56
        color: Qt.rgba(1, 1, 1, 0.015)

        // Right edge glow
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.08) }
                GradientStop { position: 0.7; color: Qt.rgba(root.stateColor.r, root.stateColor.g, root.stateColor.b, 0.08) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            spacing: 8

            // ZYZZ logo
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Z"
                color: root.stateColor
                font.pixelSize: 20
                font.weight: Font.Bold
                font.letterSpacing: 2
                opacity: 0.7

                Behavior on color { ColorAnimation { duration: 1000 } }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.7; duration: 3000; easing.type: Easing.InOutSine }
                }
            }

            Item { width: 1; height: 12 }

            // Nav separator
            Rectangle {
                width: 24; height: 1
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            Item { width: 1; height: 8 }

            // Nav icons
            Repeater {
                model: ListModel {
                    ListElement { icon: "\u25C9"; label: "AI"; action: "ai" }
                    ListElement { icon: "\u2630"; label: "History"; action: "history" }
                    ListElement { icon: "\u29BF"; label: "Memory"; action: "memory" }
                    ListElement { icon: "\u2699"; label: "Settings"; action: "settings" }
                }

                Rectangle {
                    width: 40; height: 40
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"

                    Behavior on color { ColorAnimation { duration: 200 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.icon
                            color: navMouse.containsMouse ? root.stateColor : "#64748b"
                            font.pixelSize: 14
                            opacity: navMouse.containsMouse ? 0.9 : 0.4

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.label
                            color: "#64748b"
                            font.pixelSize: 7
                            font.letterSpacing: 1
                            opacity: navMouse.containsMouse ? 0.6 : 0.25
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.action === "history") historyDrawer.open()
                        }
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 4 — HUD Panels
    // ══════════════════════════════════════════════════════════

    // ── Top-left: Clock + Date ──
    Column {
        anchors.left: navBar.right
        anchors.top: parent.top
        anchors.leftMargin: 24
        anchors.topMargin: 20
        spacing: 2

        Text {
            text: root.clockText
            color: "#e2e8f0"
            font.pixelSize: 28
            font.weight: Font.Light
            font.family: "Consolas"
            font.letterSpacing: 4
            opacity: 0.5
        }
        Text {
            text: root.dateText
            color: "#64748b"
            font.pixelSize: 9
            font.letterSpacing: 3
            font.family: "Consolas"
            opacity: 0.35
        }
    }

    // ── Top-right: Status indicator ──
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 24
        anchors.topMargin: 24
        spacing: 8
        opacity: zyzz.state !== "idle" ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Rectangle {
            width: 6; height: 6; radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: root.stateColor
            Behavior on color { ColorAnimation { duration: 600 } }

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        Text {
            text: {
                switch (zyzz.state) {
                    case "listening": return "LISTENING"
                    case "thinking": return "PROCESSING"
                    case "speaking": return "STREAMING"
                    case "error": return "ERROR"
                    default: return "STANDBY"
                }
            }
            color: root.stateColor
            font.pixelSize: 10
            font.letterSpacing: 3
            font.weight: Font.Medium
            font.family: "Consolas"
            Behavior on color { ColorAnimation { duration: 600 } }
        }
    }

    // ── Bottom-left: System telemetry ──
    Column {
        anchors.left: navBar.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 24
        spacing: 6

        // Section label
        Text {
            text: "TELEMETRY"
            color: "#64748b"
            font.pixelSize: 8
            font.letterSpacing: 3
            font.family: "Consolas"
            opacity: 0.3
        }

        Rectangle { width: 80; height: 1; color: Qt.rgba(1, 1, 1, 0.04) }

        // Uptime
        Row {
            spacing: 8
            Text { text: "UPTIME"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text { text: root.uptimeText; color: "#94a3b8"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }

        // Session
        Row {
            spacing: 8
            Text { text: "SESSION"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text { text: "ACTIVE"; color: "#10b981"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }

        // Engine
        Row {
            spacing: 8
            Text { text: "ENGINE"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text { text: "GEMINI"; color: "#3b82f6"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }

        // Neural link
        Row {
            spacing: 8
            Text { text: "LINK"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Rectangle {
                width: 6; height: 6; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: "#10b981"; opacity: 0.6

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.6; duration: 2000; easing.type: Easing.InOutSine }
                }
            }
            Text { text: "ONLINE"; color: "#10b981"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }
    }

    // ── Bottom-right: Model info + Voice ──
    Column {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 6

        Text {
            text: "INTERFACE"
            color: "#64748b"
            font.pixelSize: 8
            font.letterSpacing: 3
            font.family: "Consolas"
            opacity: 0.3
            anchors.right: parent.right
        }

        Rectangle { width: 80; height: 1; color: Qt.rgba(1, 1, 1, 0.04); anchors.right: parent.right }

        Row {
            spacing: 8
            anchors.right: parent.right
            Text { text: "MODEL"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text { text: "GEMINI-2.0-FLASH"; color: "#94a3b8"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }

        Row {
            spacing: 8
            anchors.right: parent.right
            Text { text: "VOICE"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text {
                text: zyzz.recording ? "RECORDING" : "STANDBY"
                color: zyzz.recording ? "#06b6d4" : "#94a3b8"
                font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }

        Row {
            spacing: 8
            anchors.right: parent.right
            Text { text: "ROUTER"; color: "#475569"; font.pixelSize: 9; font.letterSpacing: 2; font.family: "Consolas"; opacity: 0.4 }
            Text { text: "ACTIVE"; color: "#10b981"; font.pixelSize: 9; font.family: "Consolas"; opacity: 0.5 }
        }
    }

    // ── HUD corner brackets ──
    // Top-left
    Canvas {
        x: navBar.width + 14; y: 10; width: 20; height: 20; opacity: 0.08
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = root.stateColor; ctx.lineWidth = 1
            ctx.beginPath(); ctx.moveTo(0, 15); ctx.lineTo(0, 0); ctx.lineTo(15, 0); ctx.stroke()
        }
        Connections { target: root; function onStateColorChanged() { parent.children[parent.children.length - 4].requestPaint && parent.children[parent.children.length - 4].requestPaint() } }
        Component.onCompleted: requestPaint()
    }
    // Top-right
    Canvas {
        anchors.right: parent.right; anchors.rightMargin: 14; y: 10; width: 20; height: 20; opacity: 0.08
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = root.stateColor; ctx.lineWidth = 1
            ctx.beginPath(); ctx.moveTo(20, 15); ctx.lineTo(20, 0); ctx.lineTo(5, 0); ctx.stroke()
        }
        Component.onCompleted: requestPaint()
    }
    // Bottom-left
    Canvas {
        x: navBar.width + 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: 20; height: 20; opacity: 0.08
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = root.stateColor; ctx.lineWidth = 1
            ctx.beginPath(); ctx.moveTo(0, 5); ctx.lineTo(0, 20); ctx.lineTo(15, 20); ctx.stroke()
        }
        Component.onCompleted: requestPaint()
    }
    // Bottom-right
    Canvas {
        anchors.right: parent.right; anchors.rightMargin: 14; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; width: 20; height: 20; opacity: 0.08
        onPaint: {
            var ctx = getContext("2d"); ctx.strokeStyle = root.stateColor; ctx.lineWidth = 1
            ctx.beginPath(); ctx.moveTo(20, 5); ctx.lineTo(20, 20); ctx.lineTo(5, 20); ctx.stroke()
        }
        Component.onCompleted: requestPaint()
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 5 — History drawer
    // ══════════════════════════════════════════════════════════

    HistoryDrawer {
        id: historyDrawer
    }

    // ══════════════════════════════════════════════════════════
    //  LAYER 6 — Main content area (center)
    // ══════════════════════════════════════════════════════════

    ColumnLayout {
        anchors.left: navBar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 60
        anchors.bottomMargin: 16
        spacing: 0

        Item { Layout.fillHeight: true }

        // ── Pipeline ──
        PipelineBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.maximumWidth: 500
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 12
            visible: zyzz.pipelineVisible
            opacity: zyzz.pipelineVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }

        // ── AI Presence (Core) ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            Layout.alignment: Qt.AlignHCenter

            ZyzzCore {
                id: aiPresence
                anchors.centerIn: parent
                width: 320
                height: 320
                aiState: zyzz.state
            }
        }

        Item { Layout.preferredHeight: 16 }

        // ── Response Panel ──
        ResponsePanel {
            id: responsePanel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 40
            Layout.maximumHeight: 280
            Layout.maximumWidth: 720
            Layout.alignment: Qt.AlignHCenter
            responseText: zyzz.responseText
            aiState: zyzz.state
            visible: zyzz.responseText !== ""
            opacity: zyzz.responseText !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }

        Item { Layout.fillHeight: true }

        // ── Input Bar ──
        InputBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.maximumWidth: 680
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            recording: zyzz.recording
            onMessageSent: function(text) { zyzz.sendMessage(text) }
            onMicToggled: zyzz.toggleRecording()
        }
    }

    // ── Scan line (ambient) ──
    Rectangle {
        id: scanLine
        anchors.left: navBar.right
        anchors.right: parent.right
        height: 1
        y: 0
        color: root.stateColor
        opacity: 0.02

        Behavior on color { ColorAnimation { duration: 1000 } }

        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: root.height; duration: 8000; easing.type: Easing.Linear }
        }
    }
}
