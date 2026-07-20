import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    minimumWidth: 1100
    minimumHeight: 700
    title: "ZYZZ — AI Command Center"
    color: "#020210"

    property string currentView: "core"

    readonly property string mono: "Consolas"
    readonly property color cyan: "#06d6f0"
    readonly property color cyanDim: "#0a4a6a"
    readonly property color panelBg: Qt.rgba(0.04, 0.06, 0.18, 0.65)
    readonly property color panelBorder: Qt.rgba(0.024, 0.84, 0.94, 0.12)

    property color sc: {
        switch (zyzz.state) {
            case "listening": return "#06d6f0"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            case "error": return "#ef4444"
            default: return "#06b8e0"
        }
    }
    Behavior on sc { ColorAnimation { duration: 800 } }

    property string clockText: ""; property string dateText: ""; property string dayText: ""
    property int uptimeSec: 0; property string uptimeText: "00:00:00"

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.clockText = Qt.formatTime(d, "HH:mm:ss")
            root.dateText = Qt.formatDate(d, "dd.MM.yyyy")
            var days = ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"]
            var doy = Math.floor((d - new Date(d.getFullYear(),0,0)) / 86400000)
            root.dayText = days[d.getDay()] + " " + (doy < 100 ? "0" : "") + (doy < 10 ? "0" : "") + doy
            root.uptimeSec++
            var h=Math.floor(root.uptimeSec/3600), m=Math.floor((root.uptimeSec%3600)/60), s=root.uptimeSec%60
            root.uptimeText = (h<10?"0":"")+h+":"+(m<10?"0":"")+m+":"+(s<10?"0":"")+s
        }
    }

    // ═══════════════════════════════════════════════════
    //  BG — Grid + nebula + glow
    // ═══════════════════════════════════════════════════

    Canvas {
        anchors.fill: parent; opacity: 0.04
        onPaint: {
            var ctx = getContext("2d"), cx=width/2, cy=height/2, mr=Math.sqrt(cx*cx+cy*cy)
            ctx.clearRect(0,0,width,height); ctx.strokeStyle="#0680c0"; ctx.lineWidth=0.5
            for(var i=1;i<=16;i++){ctx.globalAlpha=(i%4===0)?0.5:0.18; ctx.beginPath(); ctx.arc(cx,cy,(mr/16)*i,0,2*Math.PI); ctx.stroke()}
            ctx.globalAlpha=0.12
            for(var j=0;j<36;j++){var a=j*Math.PI*2/36; ctx.beginPath(); ctx.moveTo(cx,cy); ctx.lineTo(cx+Math.cos(a)*mr,cy+Math.sin(a)*mr); ctx.stroke()}
        }
        Component.onCompleted: requestPaint()
    }

    Canvas {
        anchors.centerIn: parent; anchors.horizontalCenterOffset:-100; anchors.verticalCenterOffset:-80
        width:800; height:800; opacity:0.035
        onPaint: {
            var ctx=getContext("2d"),cx=width/2,cy=height/2; ctx.clearRect(0,0,width,height)
            var g=ctx.createRadialGradient(cx,cy,0,cx,cy,400)
            g.addColorStop(0,Qt.rgba(0.02,0.45,0.9,0.5)); g.addColorStop(0.4,Qt.rgba(0.1,0.2,0.7,0.2)); g.addColorStop(1,"transparent")
            ctx.fillStyle=g; ctx.fillRect(0,0,width,height)
        }
        Component.onCompleted: requestPaint()
    }

    Canvas {
        id: ambGlow; anchors.centerIn: parent; anchors.verticalCenterOffset: -10
        width: root.width*0.7; height: width; opacity: 0.5
        onPaint: {
            var ctx=getContext("2d"),cx=width/2,cy=height/2; ctx.clearRect(0,0,width,height)
            var g=ctx.createRadialGradient(cx,cy,0,cx,cy,cx)
            g.addColorStop(0,Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.2))
            g.addColorStop(0.3,Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.06))
            g.addColorStop(0.7,Qt.rgba(root.sc.r,root.sc.g,root.sc.b,0.01))
            g.addColorStop(1,"transparent"); ctx.fillStyle=g; ctx.fillRect(0,0,width,height)
        }
        Connections { target: root; function onScChanged() { ambGlow.requestPaint() } }
    }

    // 80 particles
    Repeater {
        model: 80
        Rectangle {
            id: ap; property real bx:Math.random()*root.width; property real by:Math.random()*root.height
            property real sz:0.5+Math.random()*2; property real bo:0.008+Math.random()*0.04
            x:bx; y:by; width:sz; height:sz; radius:sz/2
            color: Math.random()>0.6?(Math.random()>0.5?"#0680c0":"#8b5cf6"):"#c8d8f0"; opacity:bo
            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: ap.by - 40 - Math.random()*100; duration: 7000+Math.random()*14000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.by + 15 + Math.random()*25; duration: 7000+Math.random()*14000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: ap.bx - 20 - Math.random()*30; duration: 10000+Math.random()*16000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.bx + 20 + Math.random()*30; duration: 10000+Math.random()*16000; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: ap.bo * 0.1; duration: 4000+Math.random()*8000; easing.type: Easing.InOutSine }
                NumberAnimation { to: ap.bo; duration: 4000+Math.random()*8000; easing.type: Easing.InOutSine }
            }
        }
    }

    // Scan lines
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; height: 1
        color: root.sc; opacity: 0.02
        Behavior on color { ColorAnimation { duration: 800 } }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: root.height; duration: 7000; easing.type: Easing.Linear }
        }
    }
    Rectangle {
        anchors.left: parent.left; anchors.right: parent.right; height: 1
        color: root.sc; opacity: 0.015
        Behavior on color { ColorAnimation { duration: 800 } }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { from: root.height; to: 0; duration: 11000; easing.type: Easing.Linear }
        }
    }

    // ═══════════════════════════════════════════════════
    //  LEFT SIDEBAR (140px, like reference)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: sidebar
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 140; color: Qt.rgba(0.02, 0.03, 0.10, 0.85)

        // Right edge glow
        Rectangle {
            anchors.right:parent.right; anchors.top:parent.top; anchors.bottom:parent.bottom; width:1
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.15) }
                GradientStop { position: 0.7; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.15) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent; anchors.topMargin: 16; anchors.bottomMargin: 12; spacing: 0

            // ZYZZ logo
            Column {
                Layout.alignment: Qt.AlignHCenter; spacing: 2
                Text { text: "ZYZZ"; color: root.cyan; font.pixelSize: 22; font.weight: Font.Bold; font.letterSpacing: 4; font.family: root.mono; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.9 }
                Text { text: "AI COMMAND CENTER"; color: "#4a7090"; font.pixelSize: 7; font.letterSpacing: 2; font.family: root.mono; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.5 }
            }

            Item { Layout.preferredHeight: 16 }

            // Logo circle
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 52; height: 52; radius: 26
                color: Qt.rgba(root.cyan.r, root.cyan.g, root.cyan.b, 0.08)
                border.color: Qt.rgba(root.cyan.r, root.cyan.g, root.cyan.b, 0.25); border.width: 1.5

                Text { anchors.centerIn: parent; text: "Z"; color: root.cyan; font.pixelSize: 24; font.weight: Font.Bold; font.family: root.mono; opacity: 0.85 }

                SequentialAnimation on border.color { loops: Animation.Infinite
                    ColorAnimation { to: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.4); duration: 2000; easing.type: Easing.InOutSine }
                    ColorAnimation { to: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.15); duration: 2000; easing.type: Easing.InOutSine }
                }
            }

            Item { Layout.preferredHeight: 14 }

            // Nav items
            Repeater {
                model: ListModel {
                    ListElement { icon: "\u25C9"; lbl: "CORE"; act: "ai"; active: true }
                    ListElement { icon: "\u2261"; lbl: "CHAT"; act: "history"; active: false }
                    ListElement { icon: "\u29BF"; lbl: "MEMORY"; act: "memory"; active: false }
                    ListElement { icon: "\u2318"; lbl: "AGENTS"; act: "agents"; active: false }
                    ListElement { icon: "\u26A1"; lbl: "AUTOMATIONS"; act: "auto"; active: false }
                    ListElement { icon: "\u2637"; lbl: "FILES"; act: "files"; active: false }
                    ListElement { icon: "\u25CE"; lbl: "VISION"; act: "vision"; active: false }
                    ListElement { icon: "\u2609"; lbl: "CALENDAR"; act: "calendar"; active: false }
                    ListElement { icon: "\uD83D\uDCB0"; lbl: "FINANCE"; act: "finance"; active: false }
                    ListElement { icon: "\u2699"; lbl: "SETTINGS"; act: "settings"; active: false }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; Layout.leftMargin: 8; Layout.rightMargin: 8
                    radius: 8
                    property bool isActive: (model.act === "ai" && root.currentView === "core") || (model.act === "finance" && root.currentView === "finance")
                    color: isActive ? Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.12) : (sideNm.containsMouse ? Qt.rgba(1,1,1,0.03) : "transparent")
                    border.color: isActive ? Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.25) : "transparent"
                    border.width: isActive ? 1 : 0
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; spacing: 10
                        Text {
                            text: model.icon; font.pixelSize: 14
                            color: isActive ? root.cyan : (sideNm.containsMouse ? "#8899bb" : "#4a5a70")
                            opacity: isActive ? 0.9 : 0.5; anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: model.lbl; font.pixelSize: 10; font.letterSpacing: 1; font.family: root.mono; font.weight: isActive ? Font.Medium : Font.Normal
                            color: isActive ? root.cyan : (sideNm.containsMouse ? "#8899bb" : "#4a5a70")
                            opacity: isActive ? 0.9 : 0.5; anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: sideNm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.act === "history") { historyDrawer.open(); return }
                            if (model.act === "finance") { root.currentView = "finance" }
                            else if (model.act === "ai") { root.currentView = "core" }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // User
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 44; Layout.leftMargin: 8; Layout.rightMargin: 8
                radius: 8; color: Qt.rgba(1,1,1,0.02)

                Row {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; spacing: 8

                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.1)
                        border.color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.2); border.width: 1
                        Text { anchors.centerIn: parent; text: "P"; color: root.cyan; font.pixelSize: 11; font.weight: Font.Bold; font.family: root.mono; opacity: 0.7 }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 1
                        Text { text: "PEDRO"; color: "#c8d8f0"; font.pixelSize: 9; font.weight: Font.Medium; font.letterSpacing: 1; font.family: root.mono; opacity: 0.6 }
                        Text { text: "OWNER"; color: "#4a5a70"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  TOP BAR
    // ═══════════════════════════════════════════════════

    Item {
        id: topBar
        anchors.left: sidebar.right; anchors.right: parent.right; anchors.top: parent.top
        height: 50

        // Clock
        Row {
            anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 16

            Text { text: root.clockText; color: "#e0e8f8"; font.pixelSize: 20; font.weight: Font.Light; font.family: root.mono; font.letterSpacing: 3; opacity: 0.6 }

            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 0
                Text { text: root.dateText; color: "#5a6a80"; font.pixelSize: 8; font.letterSpacing: 2; font.family: root.mono; opacity: 0.45 }
                Text { text: root.dayText; color: "#4a5a70"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.35 }
            }
        }

        // ONLINE badge (center)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.verticalCenter: parent.verticalCenter
            width: onlineLbl.implicitWidth + 28; height: 24; radius: 12
            color: Qt.rgba(0.024,0.84,0.94,0.06); border.color: Qt.rgba(0.024,0.84,0.94,0.2); border.width: 1

            Text { id: onlineLbl; anchors.centerIn: parent; text: "ONLINE"; color: root.cyan; font.pixelSize: 10; font.letterSpacing: 3; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
        }

        // Voice + System Status (right)
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 20

            // Voice waveform
            Row {
                spacing: 2; anchors.verticalCenter: parent.verticalCenter

                Text { text: "Voice Active"; color: "#5a7a90"; font.pixelSize: 9; font.family: root.mono; opacity: 0.45; anchors.verticalCenter: parent.verticalCenter }

                Item { width: 6; height: 1 }

                // Mini waveform bars
                Repeater {
                    model: 16
                    Rectangle {
                        id: wBar
                        width: 2; height: 3 + Math.random() * 10; radius: 1
                        color: root.cyan; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height { loops: Animation.Infinite
                            NumberAnimation { to: 2 + Math.random()*14; duration: 300+Math.random()*500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 2 + Math.random()*4; duration: 300+Math.random()*500; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // System Status
            Column {
                anchors.verticalCenter: parent.verticalCenter; spacing: 0
                Text { text: "System Status"; color: "#5a7a90"; font.pixelSize: 8; font.family: root.mono; opacity: 0.4; anchors.right: parent.right }
                Text { text: "OPTIMAL"; color: "#10b981"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 2; font.family: root.mono; opacity: 0.7; anchors.right: parent.right }
            }
        }

        // Bottom line
        Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.06) }
    }

    // ═══════════════════════════════════════════════════
    //  CENTER — AI CORE (huge)
    // ═══════════════════════════════════════════════════

    ZyzzCore {
        id: aiCore
        visible: root.currentView === "core"
        anchors.horizontalCenter: coreArea.horizontalCenter
        anchors.verticalCenter: coreArea.verticalCenter
        anchors.verticalCenterOffset: -15
        width: Math.min(coreArea.width * 0.52, coreArea.height * 0.72)
        height: width
        aiState: zyzz.state
    }

    // "ZZ" text on core
    Text {
        visible: root.currentView === "core"
        anchors.centerIn: aiCore; text: "ZZ"; color: "#fff"
        font.pixelSize: aiCore.width * 0.12; font.weight: Font.Bold; font.family: root.mono; font.letterSpacing: 6
        opacity: 0.25
        SequentialAnimation on opacity { loops: Animation.Infinite
            NumberAnimation { to: 0.12; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.25; duration: 3000; easing.type: Easing.InOutSine }
        }
    }

    // ═══════════════════════════════════════════════════
    //  CONTENT AREA reference
    // ═══════════════════════════════════════════════════

    Item {
        id: coreArea
        anchors.left: sidebar.right; anchors.right: parent.right
        anchors.top: topBar.bottom; anchors.bottom: parent.bottom
    }

    // ═══════════════════════════════════════════════════
    //  FINANCE — WebEngineView
    // ═══════════════════════════════════════════════════

    WebEngineView {
        id: financeView
        visible: root.currentView === "finance"
        anchors.fill: coreArea
        url: Qt.resolvedUrl("../web/finance.html")
        backgroundColor: "#0a0a1a"
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: System Overview (left)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: sysPanel
        visible: root.currentView === "core"
        x: sidebar.width + 16; y: topBar.height + 12
        width: 200; height: 175; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "SYSTEM OVERVIEW"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            // CPU
            Row { spacing: 6; width: parent.width
                Column { spacing: 1; width: 50
                    Text { text: "CPU"; color: "#5a7a90"; font.pixelSize: 8; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    Text { text: Math.floor(zyzz.cpuPercent) + "%"; color: "#e0e8f8"; font.pixelSize: 13; font.weight: Font.Medium; font.family: root.mono; opacity: 0.7 }
                }
                // Mini sparkline
                Canvas {
                    width: parent.width - 60; height: 24; anchors.verticalCenter: parent.verticalCenter
                    property real tick: 0
                    Timer { interval: 500; running: true; repeat: true; onTriggered: { parent.tick++; parent.requestPaint() } }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                        ctx.strokeStyle = root.cyan; ctx.lineWidth = 1; ctx.globalAlpha = 0.4
                        ctx.beginPath()
                        for (var i = 0; i < 20; i++) {
                            var v = height/2 + Math.sin((tick+i)*0.5)*height*0.3 + Math.random()*4-2
                            if (i===0) ctx.moveTo(0,v); else ctx.lineTo(i*width/19,v)
                        }
                        ctx.stroke()
                    }
                }
            }

            // MEMORY
            Row { spacing: 6; width: parent.width
                Column { spacing: 1; width: 50
                    Text { text: "MEMORY"; color: "#5a7a90"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    Text { text: zyzz.memUsed.toFixed(1) + " GB / " + zyzz.memTotal.toFixed(0) + " GB"; color: "#e0e8f8"; font.pixelSize: 9; font.family: root.mono; opacity: 0.6; width: 130 }
                }
            }

            // DISK
            Row { spacing: 6; width: parent.width
                Column { spacing: 1; width: 50
                    Text { text: "DISK"; color: "#5a7a90"; font.pixelSize: 8; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    Text { text: zyzz.diskUsed.toFixed(0) + " / " + zyzz.diskTotal.toFixed(0) + " GB"; color: "#e0e8f8"; font.pixelSize: 9; font.family: root.mono; opacity: 0.6 }
                }
            }

            // MEM %
            Row { spacing: 6; width: parent.width
                Column { spacing: 1
                    Text { text: "RAM USAGE"; color: "#5a7a90"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                    Text { text: Math.floor(zyzz.memPercent) + "%"; color: "#e0e8f8"; font.pixelSize: 13; font.weight: Font.Medium; font.family: root.mono; opacity: 0.7 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: AI Models (left, below system)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: aiModelsPanel
        visible: root.currentView === "core"
        x: sidebar.width + 16; y: sysPanel.y + sysPanel.height + 10
        width: 200; height: 155; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "AI MODELS"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            Repeater {
                model: ListModel {
                    ListElement { name: "GEMINI 2.0"; status: "ACTIVE"; clr: "#10b981" }
                    ListElement { name: "CLAUDE 4"; status: "API KEY MISSING"; clr: "#8b5cf6" }
                    ListElement { name: "GPT-4o"; status: "API KEY MISSING"; clr: "#f59e0b" }
                    ListElement { name: "LOCAL MODEL"; status: "NOT CONFIGURED"; clr: "#475569" }
                }

                Row {
                    width: parent.width; spacing: 0

                    Column {
                        spacing: 1; width: parent.width - 30
                        Text { text: model.name; color: "#c8d8f0"; font.pixelSize: 10; font.weight: Font.Medium; font.family: root.mono; opacity: 0.65 }
                        Text { text: model.status; color: model.clr; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.55 }
                    }

                    Rectangle {
                        width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter
                        color: model.clr; opacity: 0.5
                        SequentialAnimation on opacity { loops: Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 1500+Math.random()*1000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.5; duration: 1500+Math.random()*1000; easing.type: Easing.InOutSine }
                        }
                    }

                    Text { text: " \u203A"; color: "#4a5a70"; font.pixelSize: 14; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: Activity Feed (right)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: activityPanel
        visible: root.currentView === "core"
        anchors.right: parent.right; anchors.rightMargin: 16; y: topBar.height + 12
        width: 220; height: 165; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "ACTIVITY FEED"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            Repeater {
                model: ListModel {
                    ListElement { icon: "\u25B6"; title: "System initialized"; desc: "All modules loaded"; time: "" }
                    ListElement { icon: "\u2B24"; title: "Gemini connected"; desc: "API key validated"; time: "" }
                    ListElement { icon: "\u29BF"; title: "Memory loaded"; desc: "Facts synced"; time: "" }
                    ListElement { icon: "\u26A1"; title: "Automations ready"; desc: "3 rules active"; time: "" }
                }

                Row {
                    width: parent.width; spacing: 8

                    Text { text: model.icon; color: root.cyan; font.pixelSize: 8; opacity: 0.4; anchors.verticalCenter: parent.verticalCenter }

                    Column {
                        spacing: 0; width: parent.width - 60
                        Text { text: model.title; color: "#c8d8f0"; font.pixelSize: 9; font.family: root.mono; opacity: 0.6 }
                        Text { text: model.desc; color: "#4a6a80"; font.pixelSize: 7; font.family: root.mono; opacity: 0.4 }
                    }

                    Text { text: root.clockText.substring(0,5); color: "#3a5a70"; font.pixelSize: 7; font.family: root.mono; opacity: 0.35; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: Live Data Stream (right, below activity)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: dataStreamPanel
        visible: root.currentView === "core"
        anchors.right: parent.right; anchors.rightMargin: 16; y: activityPanel.y + activityPanel.height + 10
        width: 220; height: 130; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "LIVE DATA STREAM"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            // Waveform canvas
            Canvas {
                id: waveCanvas; width: parent.width; height: 40
                property real tick: 0
                Timer { interval: 80; running: true; repeat: true; onTriggered: { waveCanvas.tick += 0.3; waveCanvas.requestPaint() } }
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                    ctx.strokeStyle = root.cyan; ctx.lineWidth = 1.2; ctx.globalAlpha = 0.45
                    ctx.beginPath()
                    for (var i = 0; i < width; i += 2) {
                        var v = height/2 + Math.sin(tick + i*0.08)*height*0.3 + Math.sin(tick*1.5 + i*0.03)*height*0.15
                        if (i===0) ctx.moveTo(i,v); else ctx.lineTo(i,v)
                    }
                    ctx.stroke()
                    // Second wave
                    ctx.globalAlpha = 0.2; ctx.strokeStyle = "#8b5cf6"
                    ctx.beginPath()
                    for (var j = 0; j < width; j += 2) {
                        var v2 = height/2 + Math.cos(tick*0.8 + j*0.06)*height*0.25
                        if (j===0) ctx.moveTo(j,v2); else ctx.lineTo(j,v2)
                    }
                    ctx.stroke()
                }
            }

            Row {
                width: parent.width; spacing: 0
                Column { width: parent.width/2; spacing: 0
                    Text { text: "TOKENS"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.totalTokens.toString(); color: "#e0e8f8"; font.pixelSize: 12; font.weight: Font.Medium; font.family: root.mono; opacity: 0.6 }
                }
                Column { width: parent.width/2; spacing: 0
                    Text { text: "MESSAGES"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4; anchors.right: parent.right }
                    Text { text: zyzz.messageCount.toString(); color: "#e0e8f8"; font.pixelSize: 12; font.weight: Font.Medium; font.family: root.mono; opacity: 0.6; anchors.right: parent.right }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: Memory Status (bottom left)
    // ═══════════════════════════════════════════════════

    Rectangle {
        id: memPanel
        visible: root.currentView === "core"
        x: sidebar.width + 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 70
        width: 200; height: 100; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "MEMORY STATUS"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            Row {
                spacing: 12

                // Circular progress
                Canvas {
                    width: 44; height: 44
                    property real pct: 0.68
                    onPaint: {
                        var ctx = getContext("2d"), cx=22, cy=22, r=18
                        ctx.clearRect(0,0,44,44)
                        ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI)
                        ctx.strokeStyle = Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.1); ctx.lineWidth = 3; ctx.stroke()
                        ctx.beginPath(); ctx.arc(cx,cy,r,-Math.PI/2,-Math.PI/2+2*Math.PI*pct)
                        ctx.strokeStyle = root.cyan; ctx.lineWidth = 3; ctx.lineCap = "round"; ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()

                    Text { anchors.centerIn: parent; text: "68%"; color: "#e0e8f8"; font.pixelSize: 9; font.weight: Font.Bold; font.family: root.mono; opacity: 0.7 }
                }

                Column {
                    spacing: 3; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "MEMORY BANK"; color: "#5a7a90"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.45 }
                    Text { text: zyzz.memoryFactsCount + " FACTS"; color: "#e0e8f8"; font.pixelSize: 10; font.family: root.mono; opacity: 0.6 }
                    Text { text: "SYNCHRONIZED"; color: "#10b981"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.5 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  PANEL: AI Status (bottom right)
    // ═══════════════════════════════════════════════════

    Rectangle {
        visible: root.currentView === "core"
        anchors.right: parent.right; anchors.rightMargin: 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 70
        width: 220; height: 100; radius: 10
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 6

            Text { text: "AI ROUTING"; color: root.cyan; font.pixelSize: 9; font.letterSpacing: 2; font.weight: Font.Medium; font.family: root.mono; opacity: 0.8 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.cyan.r,root.cyan.g,root.cyan.b,0.08) }

            Row { spacing: 20
                Column { spacing: 1
                    Text { text: "MODEL"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.activeModel; color: "#e0e8f8"; font.pixelSize: 10; font.weight: Font.Medium; font.family: root.mono; opacity: 0.6 }
                }
                Column { spacing: 1
                    Text { text: "TOKENS"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.totalTokens.toString(); color: "#e0e8f8"; font.pixelSize: 10; font.weight: Font.Medium; font.family: root.mono; opacity: 0.6 }
                }
                Column { spacing: 1
                    Text { text: "CONVOS"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.conversationCount.toString(); color: "#e0e8f8"; font.pixelSize: 10; font.family: root.mono; opacity: 0.6 }
                }
            }

            Row { spacing: 20
                Column { spacing: 1
                    Text { text: "VOICE"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text {
                        text: zyzz.recording ? "RECORDING" : "READY"
                        color: zyzz.recording ? "#06d6f0" : "#10b981"
                        font.pixelSize: 8; font.family: root.mono; opacity: 0.55
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
                Column { spacing: 1
                    Text { text: "MEMORY"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.memoryFactsCount + " FACTS"; color: "#e0e8f8"; font.pixelSize: 8; font.family: root.mono; opacity: 0.5 }
                }
                Column { spacing: 1
                    Text { text: "AUTOS"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 1; font.family: root.mono; opacity: 0.4 }
                    Text { text: zyzz.automationsCount + " RULES"; color: "#e0e8f8"; font.pixelSize: 8; font.family: root.mono; opacity: 0.5 }
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════
    //  BOTTOM — Status text + Response + Input
    // ═══════════════════════════════════════════════════

    // Status text (above input, like "ZYZZ IS THINKING...")
    Rectangle {
        id: statusBubble
        anchors.horizontalCenter: coreArea.horizontalCenter
        anchors.bottom: responsePanel.visible ? responsePanel.top : inputBar.top
        anchors.bottomMargin: 8
        width: statusRow.implicitWidth + 30; height: 28; radius: 14
        color: root.panelBg; border.color: root.panelBorder; border.width: 1
        visible: root.currentView === "core" && zyzz.state !== "idle"
        opacity: zyzz.state !== "idle" ? 0.85 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Row {
            id: statusRow; anchors.centerIn: parent; spacing: 8

            Rectangle {
                width: 6; height: 6; radius: 3; color: root.sc; anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: { switch(zyzz.state) { case "listening": return "ZYZZ IS LISTENING..."; case "thinking": return "ZYZZ IS THINKING..."; case "speaking": return "STREAMING RESPONSE..."; case "error": return "ERROR OCCURRED"; default: return "" } }
                color: root.sc; font.pixelSize: 9; font.letterSpacing: 1; font.weight: Font.Medium; font.family: root.mono
                Behavior on color { ColorAnimation { duration: 600 } }
            }
        }
    }

    // Response panel
    ResponsePanel {
        id: responsePanel
        anchors.horizontalCenter: coreArea.horizontalCenter
        anchors.bottom: inputBar.top; anchors.bottomMargin: 8
        width: Math.min(coreArea.width * 0.6, 680)
        height: Math.min(implicitHeight, 200)
        visible: root.currentView === "core" && zyzz.responseText !== ""
        opacity: zyzz.responseText !== "" ? 1 : 0
        responseText: zyzz.responseText; aiState: zyzz.state
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    // Input bar
    InputBar {
        id: inputBar
        visible: root.currentView === "core"
        anchors.horizontalCenter: coreArea.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 14
        width: Math.min(coreArea.width * 0.65, 720)
        height: 72
        recording: zyzz.recording
        onMessageSent: function(text) { zyzz.sendMessage(text) }
        onMicToggled: zyzz.toggleRecording()
    }

    // ═══════════════════════════════════════════════════
    //  BOTTOM-LEFT — Quantum core temp
    // ═══════════════════════════════════════════════════

    Rectangle {
        visible: root.currentView === "core"
        x: sidebar.width + 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 12
        width: 140; height: 55; radius: 8
        color: root.panelBg; border.color: root.panelBorder; border.width: 1

        Column {
            anchors.fill: parent; anchors.margins: 8; spacing: 2
            Text { text: "CPU LOAD"; color: "#4a6a80"; font.pixelSize: 7; font.letterSpacing: 2; font.family: root.mono; opacity: 0.4 }

            Row { spacing: 6
                Text { text: Math.floor(zyzz.cpuPercent) + "%"; color: "#e0e8f8"; font.pixelSize: 18; font.weight: Font.Light; font.family: root.mono; opacity: 0.6 }

                // Mini temp chart
                Canvas {
                    width: 60; height: 20; anchors.verticalCenter: parent.verticalCenter
                    property real tick: 0
                    Timer { interval: 600; running: true; repeat: true; onTriggered: { parent.tick++; parent.requestPaint() } }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)
                        ctx.strokeStyle = root.cyan; ctx.lineWidth = 1; ctx.globalAlpha = 0.35
                        ctx.beginPath()
                        for (var i=0; i<15; i++) {
                            var v = height/2 + Math.sin(tick*0.4+i*0.6)*height*0.3
                            if(i===0) ctx.moveTo(0,v); else ctx.lineTo(i*width/14,v)
                        }
                        ctx.stroke()
                    }
                }
            }

            Text { text: "OPTIMAL"; color: "#10b981"; font.pixelSize: 8; font.letterSpacing: 2; font.weight: Font.Bold; font.family: root.mono; opacity: 0.55 }
        }
    }

    // ═══════════════════════════════════════════════════
    //  History drawer
    // ═══════════════════════════════════════════════════

    HistoryDrawer { id: historyDrawer }

    // ═══════════════════════════════════════════════════
    //  Pipeline (shown over core when active)
    // ═══════════════════════════════════════════════════

    PipelineBar {
        anchors.horizontalCenter: coreArea.horizontalCenter
        y: topBar.height + 8; width: 400; height: 24
        visible: root.currentView === "core" && zyzz.pipelineVisible
        opacity: zyzz.pipelineVisible ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }
}
