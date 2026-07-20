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

    property color sc: {
        switch (zyzz.state) {
            case "listening": return "#06b6d4"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            case "error": return "#ef4444"
            default: return "#3b82f6"
        }
    }
    Behavior on sc { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

    property string clockText: ""
    property string dateText: ""
    property int uptimeSeconds: 0
    property string uptimeText: "00:00:00"
    property real simLatency: 23
    property real simTokens: 0

    // Counters
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.clockText = Qt.formatTime(d, "HH:mm:ss")
            root.dateText = Qt.formatDate(d, "dd MMM yyyy").toUpperCase()
            root.uptimeSeconds++
            var h = Math.floor(root.uptimeSeconds / 3600)
            var m = Math.floor((root.uptimeSeconds % 3600) / 60)
            var s = root.uptimeSeconds % 60
            root.uptimeText = (h<10?"0":"") + h + ":" + (m<10?"0":"") + m + ":" + (s<10?"0":"") + s
            root.simLatency = 18 + Math.random() * 15
            root.simTokens += Math.floor(Math.random() * 5)
        }
    }

    // Font shorthand
    readonly property string mono: "Consolas"

    // ══════════════════════════════════════════════════════════════
    //  BG LAYER 0 — Polar grid
    // ══════════════════════════════════════════════════════════════

    Canvas {
        anchors.fill: parent; opacity: 0.035
        onPaint: {
            var ctx = getContext("2d"), cx = width/2, cy = height/2
            var maxR = Math.sqrt(cx*cx + cy*cy)
            ctx.clearRect(0,0,width,height)
            ctx.strokeStyle = "#3b82f6"; ctx.lineWidth = 0.5
            for (var i = 1; i <= 16; i++) {
                ctx.globalAlpha = (i % 4 === 0) ? 0.5 : 0.2
                ctx.beginPath(); ctx.arc(cx,cy,(maxR/16)*i,0,2*Math.PI); ctx.stroke()
            }
            ctx.globalAlpha = 0.15
            for (var j = 0; j < 36; j++) {
                var a = j * Math.PI * 2 / 36
                ctx.beginPath(); ctx.moveTo(cx,cy)
                ctx.lineTo(cx+Math.cos(a)*maxR, cy+Math.sin(a)*maxR); ctx.stroke()
            }
        }
        Component.onCompleted: requestPaint()
    }

    // ── Nebula blobs ──
    Canvas {
        anchors.centerIn: parent; anchors.horizontalCenterOffset: -250; anchors.verticalCenterOffset: -120
        width: 700; height: 700; opacity: 0.03
        onPaint: {
            var ctx = getContext("2d"), cx = width/2, cy = height/2
            ctx.clearRect(0,0,width,height)
            var g = ctx.createRadialGradient(cx,cy,0,cx,cy,350)
            g.addColorStop(0, Qt.rgba(0.23,0.36,0.96,0.45)); g.addColorStop(0.5, Qt.rgba(0.55,0.36,0.96,0.15)); g.addColorStop(1,"transparent")
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height)
        }
        Component.onCompleted: requestPaint()
    }
    Canvas {
        anchors.centerIn: parent; anchors.horizontalCenterOffset: 280; anchors.verticalCenterOffset: 80
        width: 550; height: 550; opacity: 0.025
        onPaint: {
            var ctx = getContext("2d"), cx = width/2, cy = height/2
            ctx.clearRect(0,0,width,height)
            var g = ctx.createRadialGradient(cx,cy,0,cx,cy,275)
            g.addColorStop(0, Qt.rgba(0.02,0.71,0.83,0.35)); g.addColorStop(0.6, Qt.rgba(0.06,0.35,0.55,0.12)); g.addColorStop(1,"transparent")
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height)
        }
        Component.onCompleted: requestPaint()
    }

    // ── Ambient glow behind core ──
    Canvas {
        id: ambGlow; anchors.centerIn: parent; anchors.verticalCenterOffset: -20
        width: root.width * 0.85; height: width; opacity: 0.45
        onPaint: {
            var ctx = getContext("2d"), cx = width/2, cy = height/2
            ctx.clearRect(0,0,width,height)
            var g = ctx.createRadialGradient(cx,cy,0,cx,cy,cx)
            g.addColorStop(0, Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.18))
            g.addColorStop(0.25, Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.06))
            g.addColorStop(0.6, Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.015))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height)
        }
        Connections { target: root; function onScChanged() { ambGlow.requestPaint() } }
    }

    // ══════════════════════════════════════════════════════════════
    //  BG LAYER 1 — 80 Atmospheric particles
    // ══════════════════════════════════════════════════════════════

    Repeater {
        model: 80
        Rectangle {
            id: ap
            property real bx: Math.random() * root.width
            property real by: Math.random() * root.height
            property real sz: 0.6 + Math.random() * 2.0
            property real bo: 0.01 + Math.random() * 0.05
            x: bx; y: by; width: sz; height: sz; radius: sz/2
            color: Math.random() > 0.6 ? (Math.random() > 0.5 ? "#3b82f6" : "#8b5cf6") : "#e2e8f0"
            opacity: bo
            SequentialAnimation on y { loops: Animation.Infinite
                NumberAnimation { to: ap.by - 50 - Math.random()*120; duration: 7000+Math.random()*15000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.by + 20 + Math.random()*30; duration: 7000+Math.random()*15000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on x { loops: Animation.Infinite
                NumberAnimation { to: ap.bx - 25 - Math.random()*35; duration: 10000+Math.random()*18000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.bx + 25 + Math.random()*35; duration: 10000+Math.random()*18000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on opacity { loops: Animation.Infinite
                NumberAnimation { to: ap.bo * 0.1; duration: 4000+Math.random()*10000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.bo; duration: 4000+Math.random()*10000; easing.type: Easing.InOutSine }
            }
        }
    }

    // ── 12 Data stream lines (vertical falling) ──
    Repeater {
        model: 12
        Rectangle {
            id: dl
            property real sx: 40 + Math.random() * (root.width - 80)
            x: sx; y: -height; width: 1; height: 20 + Math.random() * 80; radius: 0.5
            color: root.sc; opacity: 0.02 + Math.random() * 0.04
            Behavior on color { ColorAnimation { duration: 1000 } }
            SequentialAnimation on y { loops: Animation.Infinite
                NumberAnimation { from: -dl.height; to: root.height + 20; duration: 5000+Math.random()*12000; easing.type: Easing.Linear }
                PauseAnimation { duration: Math.random() * 5000 }
            }
        }
    }

    // ── 2 Horizontal scan lines ──
    Rectangle {
        id: hScan1; anchors.left: parent.left; anchors.right: parent.right
        height: 1; y: 0; color: root.sc; opacity: 0.025
        Behavior on color { ColorAnimation { duration: 1000 } }
        SequentialAnimation on y { loops: Animation.Infinite
            NumberAnimation { from: 0; to: root.height; duration: 7000; easing.type: Easing.Linear }
        }
    }
    Rectangle {
        id: hScan2; anchors.left: parent.left; anchors.right: parent.right
        height: 1; y: root.height; color: root.sc; opacity: 0.015
        Behavior on color { ColorAnimation { duration: 1000 } }
        SequentialAnimation on y { loops: Animation.Infinite
            NumberAnimation { from: root.height; to: 0; duration: 11000; easing.type: Easing.Linear }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  Mouse glow
    // ══════════════════════════════════════════════════════════════

    MouseArea {
        id: mTrack; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.NoButton; propagateComposedEvents: true
    }
    Canvas {
        x: mTrack.mouseX - 100; y: mTrack.mouseY - 100
        width: 200; height: 200; visible: mTrack.containsMouse; opacity: 0.07
        onPaint: {
            var ctx = getContext("2d"); ctx.clearRect(0,0,200,200)
            var g = ctx.createRadialGradient(100,100,0,100,100,100)
            g.addColorStop(0, Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.5)); g.addColorStop(1,"transparent")
            ctx.fillStyle = g; ctx.fillRect(0,0,200,200)
        }
        Connections { target: root; function onScChanged() { parent.children[parent.children.length-1] } }
    }

    // ══════════════════════════════════════════════════════════════
    //  LEFT PANEL — Tactical nav + system readouts
    // ══════════════════════════════════════════════════════════════

    Item {
        id: leftPanel
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 54

        // Edge line
        Rectangle {
            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.2; color: Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.06) }
                GradientStop { position: 0.8; color: Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.06) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 16
            spacing: 4

            // Logo
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Z"; color: root.sc; font.pixelSize: 18; font.weight: Font.Bold; font.letterSpacing: 2; opacity: 0.7
                Behavior on color { ColorAnimation { duration: 1000 } }
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 3000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.7; duration: 3000; easing.type: Easing.InOutSine }
                }
            }

            Item { width:1; height: 8 }
            Rectangle { width: 20; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(1,1,1,0.05) }
            Item { width:1; height: 6 }

            // Tactical nav icons
            Repeater {
                model: ListModel {
                    ListElement { sym: "\u25C9"; lbl: "CORE"; act: "ai" }
                    ListElement { sym: "\u2261"; lbl: "LOGS"; act: "history" }
                    ListElement { sym: "\u29BF"; lbl: "MEM"; act: "memory" }
                    ListElement { sym: "\u2318"; lbl: "TOOLS"; act: "tools" }
                    ListElement { sym: "\u2699"; lbl: "SYS"; act: "settings" }
                }

                Item {
                    width: 44; height: 38
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        anchors.fill: parent; radius: 6
                        color: nm.containsMouse ? Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.06) : "transparent"
                        border.color: nm.containsMouse ? Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.1) : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.sym; color: nm.containsMouse ? root.sc : "#475569"
                            font.pixelSize: 13; opacity: nm.containsMouse ? 0.9 : 0.35
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: model.lbl; color: "#475569"; font.pixelSize: 6; font.letterSpacing: 1; font.family: root.mono
                            opacity: nm.containsMouse ? 0.5 : 0.2
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (model.act === "history") historyDrawer.open() }
                    }
                }
            }

            Item { width:1; height: 8 }
            Rectangle { width: 20; height: 1; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(1,1,1,0.03) }
            Item { width:1; height: 6 }

            // Left panel subsystem indicators
            Repeater {
                model: ListModel {
                    ListElement { lbl: "VOICE"; clr: "#06b6d4" }
                    ListElement { lbl: "VISION"; clr: "#8b5cf6" }
                    ListElement { lbl: "TOOLS"; clr: "#10b981" }
                    ListElement { lbl: "CAL"; clr: "#f59e0b" }
                    ListElement { lbl: "EMAIL"; clr: "#ef4444" }
                    ListElement { lbl: "FILES"; clr: "#6366f1" }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Rectangle {
                        width: 4; height: 4; radius: 2; color: model.clr; opacity: 0.4
                        anchors.verticalCenter: parent.verticalCenter
                        SequentialAnimation on opacity { loops: Animation.Infinite
                            NumberAnimation { to: 0.15; duration: 2000+Math.random()*3000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.4; duration: 2000+Math.random()*3000; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        text: model.lbl; color: "#475569"; font.pixelSize: 6; font.letterSpacing: 1; font.family: root.mono
                        opacity: 0.25
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  TOP HUD — Clock, status, system
    // ══════════════════════════════════════════════════════════════

    // Clock
    Column {
        anchors.left: leftPanel.right; anchors.top: parent.top
        anchors.leftMargin: 20; anchors.topMargin: 16; spacing: 1

        Text { text: root.clockText; color: "#e2e8f0"; font.pixelSize: 24; font.weight: Font.Light; font.family: root.mono; font.letterSpacing: 4; opacity: 0.45 }
        Text { text: root.dateText; color: "#64748b"; font.pixelSize: 8; font.letterSpacing: 3; font.family: root.mono; opacity: 0.3 }
    }

    // Status + pipeline (top-right)
    Column {
        anchors.right: parent.right; anchors.top: parent.top
        anchors.rightMargin: 20; anchors.topMargin: 16; spacing: 4

        Row {
            spacing: 6; anchors.right: parent.right
            Rectangle {
                width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                color: root.sc; Behavior on color { ColorAnimation { duration: 600 } }
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }
            Text {
                text: { switch(zyzz.state) { case "listening": return "LISTENING"; case "thinking": return "PROCESSING"; case "speaking": return "STREAMING"; case "error": return "ERROR"; default: return "STANDBY" } }
                color: root.sc; font.pixelSize: 10; font.letterSpacing: 3; font.weight: Font.Medium; font.family: root.mono
                Behavior on color { ColorAnimation { duration: 600 } }
            }
        }

        // Pipeline
        PipelineBar {
            width: 400; height: 20; anchors.right: parent.right
            visible: zyzz.pipelineVisible
            opacity: zyzz.pipelineVisible ? 0.7 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  BOTTOM-LEFT — Dense telemetry readouts
    // ══════════════════════════════════════════════════════════════

    Column {
        anchors.left: leftPanel.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 20; anchors.bottomMargin: 20; spacing: 4

        Text { text: "SYSTEM TELEMETRY"; color: "#475569"; font.pixelSize: 7; font.letterSpacing: 3; font.family: root.mono; opacity: 0.25 }
        Rectangle { width: 120; height: 1; color: Qt.rgba(1,1,1,0.03) }

        Repeater {
            model: ListModel {
                ListElement { k: "UPTIME"; isDynamic: true }
                ListElement { k: "SESSION"; isDynamic: false }
                ListElement { k: "ENGINE"; isDynamic: false }
                ListElement { k: "ROUTER"; isDynamic: false }
                ListElement { k: "MEMORY"; isDynamic: false }
                ListElement { k: "NETWORK"; isDynamic: false }
                ListElement { k: "GPU"; isDynamic: false }
                ListElement { k: "THREADS"; isDynamic: false }
            }

            Row {
                spacing: 6
                Text { text: model.k; color: "#334155"; font.pixelSize: 8; font.letterSpacing: 2; font.family: root.mono; opacity: 0.4; width: 55 }

                Rectangle {
                    width: 4; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter
                    color: "#10b981"; opacity: 0.35
                    SequentialAnimation on opacity { loops: Animation.Infinite
                        NumberAnimation { to: 0.12; duration: 1500+index*400; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.35; duration: 1500+index*400; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: {
                        switch (index) {
                            case 0: return root.uptimeText
                            case 1: return "ACTIVE"
                            case 2: return "GEMINI-2.0"
                            case 3: return "ONLINE"
                            case 4: return "128 FACTS"
                            case 5: return "CONNECTED"
                            case 6: return "NOMINAL"
                            case 7: return "4 / 8"
                            default: return "--"
                        }
                    }
                    color: index === 1 || index === 3 || index === 5 ? "#10b981" : "#64748b"
                    font.pixelSize: 8; font.family: root.mono; opacity: 0.45
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  BOTTOM-RIGHT — AI routing / model info
    // ══════════════════════════════════════════════════════════════

    Column {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 20; anchors.bottomMargin: 20; spacing: 4

        Text { text: "AI ROUTING"; color: "#475569"; font.pixelSize: 7; font.letterSpacing: 3; font.family: root.mono; opacity: 0.25; anchors.right: parent.right }
        Rectangle { width: 120; height: 1; color: Qt.rgba(1,1,1,0.03); anchors.right: parent.right }

        Repeater {
            model: ListModel {
                ListElement { k: "MODEL"; v: "GEMINI-2.0-FLASH" }
                ListElement { k: "LATENCY"; v: "" }
                ListElement { k: "TOKENS"; v: "" }
                ListElement { k: "VOICE"; v: "" }
                ListElement { k: "TOOLS"; v: "12 ACTIVE" }
                ListElement { k: "CALENDAR"; v: "SYNCED" }
                ListElement { k: "AUTOMATIONS"; v: "3 RULES" }
                ListElement { k: "TEMP"; v: "0.7" }
            }

            Row {
                spacing: 6; anchors.right: parent.right; layoutDirection: Qt.RightToLeft

                Text {
                    text: {
                        switch (index) {
                            case 1: return Math.floor(root.simLatency) + "ms"
                            case 2: return root.simTokens + " TKN"
                            case 3: return zyzz.recording ? "RECORDING" : "STANDBY"
                            default: return model.v
                        }
                    }
                    color: {
                        if (index === 3 && zyzz.recording) return "#06b6d4"
                        if (index === 5) return "#10b981"
                        return "#64748b"
                    }
                    font.pixelSize: 8; font.family: root.mono; opacity: 0.45
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Rectangle {
                    width: 4; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter
                    color: root.sc; opacity: 0.3
                    Behavior on color { ColorAnimation { duration: 1000 } }
                    SequentialAnimation on opacity { loops: Animation.Infinite
                        NumberAnimation { to: 0.1; duration: 1800+index*300; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.3; duration: 1800+index*300; easing.type: Easing.InOutSine }
                    }
                }

                Text { text: model.k; color: "#334155"; font.pixelSize: 8; font.letterSpacing: 2; font.family: root.mono; opacity: 0.4 }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  RIGHT EDGE — Data flow indicators
    // ══════════════════════════════════════════════════════════════

    Column {
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter; spacing: 3

        Repeater {
            model: 20
            Rectangle {
                width: 2; height: 2 + Math.random() * 8; radius: 1
                color: root.sc; opacity: 0.03 + Math.random() * 0.06
                anchors.right: parent.right
                Behavior on color { ColorAnimation { duration: 1000 } }
                SequentialAnimation on opacity { loops: Animation.Infinite
                    NumberAnimation { to: 0.01; duration: 800+Math.random()*2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.03 + Math.random()*0.06; duration: 800+Math.random()*2000; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    //  HUD corner brackets
    // ══════════════════════════════════════════════════════════════

    Canvas {
        id: cTL; x: leftPanel.width + 10; y: 8; width: 24; height: 24; opacity: 0.07
        onPaint: { var ctx = getContext("2d"); ctx.strokeStyle = root.sc; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(0,18); ctx.lineTo(0,0); ctx.lineTo(18,0); ctx.stroke() }
        Component.onCompleted: requestPaint()
        Connections { target: root; function onScChanged() { cTL.requestPaint() } }
    }
    Canvas {
        id: cTR; anchors.right: parent.right; anchors.rightMargin: 10; y: 8; width: 24; height: 24; opacity: 0.07
        onPaint: { var ctx = getContext("2d"); ctx.strokeStyle = root.sc; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(24,18); ctx.lineTo(24,0); ctx.lineTo(6,0); ctx.stroke() }
        Component.onCompleted: requestPaint()
        Connections { target: root; function onScChanged() { cTR.requestPaint() } }
    }
    Canvas {
        id: cBL; x: leftPanel.width + 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 24; height: 24; opacity: 0.07
        onPaint: { var ctx = getContext("2d"); ctx.strokeStyle = root.sc; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(0,6); ctx.lineTo(0,24); ctx.lineTo(18,24); ctx.stroke() }
        Component.onCompleted: requestPaint()
        Connections { target: root; function onScChanged() { cBL.requestPaint() } }
    }
    Canvas {
        id: cBR; anchors.right: parent.right; anchors.rightMargin: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 24; height: 24; opacity: 0.07
        onPaint: { var ctx = getContext("2d"); ctx.strokeStyle = root.sc; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(24,6); ctx.lineTo(24,24); ctx.lineTo(6,24); ctx.stroke() }
        Component.onCompleted: requestPaint()
        Connections { target: root; function onScChanged() { cBR.requestPaint() } }
    }

    // ══════════════════════════════════════════════════════════════
    //  History drawer
    // ══════════════════════════════════════════════════════════════

    HistoryDrawer { id: historyDrawer }

    // ══════════════════════════════════════════════════════════════
    //  CENTER — AI Core (HUGE) + Response + Input
    // ══════════════════════════════════════════════════════════════

    Item {
        id: centerArea
        anchors.left: leftPanel.right; anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.leftMargin: 10; anchors.rightMargin: 10
        anchors.topMargin: 50; anchors.bottomMargin: 10

        // ── AI CORE — fills ~35% of screen ──
        ZyzzCore {
            id: aiPresence
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -40
            width: Math.min(parent.width * 0.55, parent.height * 0.65)
            height: width
            aiState: zyzz.state
        }

        // ── Response Panel (overlays bottom of core area) ──
        ResponsePanel {
            id: responsePanel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: inputBar.top
            anchors.bottomMargin: 12
            width: Math.min(parent.width * 0.65, 720)
            height: Math.min(implicitHeight, 240)
            visible: zyzz.responseText !== ""
            opacity: zyzz.responseText !== "" ? 1 : 0
            responseText: zyzz.responseText
            aiState: zyzz.state
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }

        // ── Input Bar (bottom) ──
        InputBar {
            id: inputBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: Math.min(parent.width * 0.7, 720)
            height: 52
            recording: zyzz.recording
            onMessageSent: function(text) { zyzz.sendMessage(text) }
            onMicToggled: zyzz.toggleRecording()
        }
    }
}
