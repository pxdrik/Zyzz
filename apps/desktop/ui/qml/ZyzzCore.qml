import QtQuick

Item {
    id: root
    property string aiState: "idle"

    property color coreColor: {
        switch (aiState) {
            case "listening": return "#06b6d4"
            case "thinking": return "#8b5cf6"
            case "speaking": return "#10b981"
            case "error": return "#ef4444"
            default: return "#3b82f6"
        }
    }
    property real intensity: {
        switch (aiState) { case "listening": return 0.95; case "thinking": return 0.85; case "speaking": return 0.9; case "error": return 1.0; default: return 0.6 }
    }
    property real breathSpeed: {
        switch (aiState) { case "listening": return 1600; case "thinking": return 800; case "speaking": return 1200; case "error": return 400; default: return 3000 }
    }
    Behavior on coreColor { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
    Behavior on intensity { NumberAnimation { duration: 1000 } }

    property real breath: 1.0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        NumberAnimation { to: 1.04; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.97; duration: root.breathSpeed; easing.type: Easing.InOutSine }
    }

    // ── Orbit angles (8 independent rotations) ──
    property real o1: 0; property real o2: 0; property real o3: 0; property real o4: 0
    property real o5: 0; property real o6: 0; property real o7: 0; property real o8: 0
    property real scanAngle: 0; property real scanAngle2: 0; property real innerAngle: 0
    property real fieldAngle: 0

    NumberAnimation on o1 { from:0; to:360; duration:8000; loops:Animation.Infinite }
    NumberAnimation on o2 { from:360; to:0; duration:11000; loops:Animation.Infinite }
    NumberAnimation on o3 { from:0; to:360; duration:16000; loops:Animation.Infinite }
    NumberAnimation on o4 { from:360; to:0; duration:22000; loops:Animation.Infinite }
    NumberAnimation on o5 { from:0; to:360; duration:30000; loops:Animation.Infinite }
    NumberAnimation on o6 { from:360; to:0; duration:40000; loops:Animation.Infinite }
    NumberAnimation on o7 { from:0; to:360; duration:55000; loops:Animation.Infinite }
    NumberAnimation on o8 { from:360; to:0; duration:75000; loops:Animation.Infinite }
    NumberAnimation on scanAngle { from:0; to:360; duration:2500; loops:Animation.Infinite }
    NumberAnimation on scanAngle2 { from:360; to:0; duration:4000; loops:Animation.Infinite }
    NumberAnimation on innerAngle { from:0; to:360; duration:5000; loops:Animation.Infinite }
    NumberAnimation on fieldAngle { from:0; to:360; duration:12000; loops:Animation.Infinite }

    // ════════════════════════════════════════════════════
    //  LAYER 0 — Massive outer glow (atmosphere)
    // ════════════════════════════════════════════════════

    Canvas {
        id: outerGlow; anchors.centerIn: parent
        width: root.width * 1.8; height: width
        opacity: 0.35 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2
            ctx.clearRect(0,0,width,height)
            var g = ctx.createRadialGradient(cx,cy,0,cx,cy,cx)
            g.addColorStop(0, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.2))
            g.addColorStop(0.25, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.08))
            g.addColorStop(0.5, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.02))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height)
        }
        Connections { target: root; function onCoreColorChanged() { outerGlow.requestPaint() } }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 1 — Magnetic field lines (outermost rotating structure)
    // ════════════════════════════════════════════════════

    Canvas {
        id: magField; anchors.centerIn: parent
        width: root.width * 1.05 * root.breath; height: width
        rotation: root.fieldAngle
        opacity: 0.04 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2 - 4
            ctx.clearRect(0,0,width,height)
            ctx.strokeStyle = root.coreColor; ctx.lineWidth = 0.4; ctx.lineCap = "round"
            // 6 field lines
            for (var i = 0; i < 6; i++) {
                var a = i * Math.PI / 3
                ctx.beginPath()
                ctx.arc(cx, cy, r, a - 0.15, a + 0.15)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.95, a + 0.3, a + 0.5)
                ctx.stroke()
            }
        }
        Connections { target: root; function onCoreColorChanged() { magField.requestPaint() } }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 2 — Scanner sweeps (2 opposing)
    // ════════════════════════════════════════════════════

    // Primary scanner
    Canvas {
        id: scanner1; anchors.centerIn: parent
        width: root.width * 0.95 * root.breath; height: width
        rotation: root.scanAngle
        opacity: 0.15 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2
            ctx.clearRect(0,0,width,height)
            ctx.beginPath(); ctx.moveTo(cx,cy)
            ctx.arc(cx, cy, r, -0.05, 0.4); ctx.closePath()
            var g = ctx.createRadialGradient(cx,cy,r*0.15,cx,cy,r)
            g.addColorStop(0, Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.5))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g; ctx.fill()
        }
        Connections { target: root; function onCoreColorChanged() { scanner1.requestPaint() } }
    }

    // Secondary scanner (opposite direction, narrower)
    Canvas {
        id: scanner2; anchors.centerIn: parent
        width: root.width * 0.85 * root.breath; height: width
        rotation: root.scanAngle2
        opacity: 0.08 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2
            ctx.clearRect(0,0,width,height)
            ctx.beginPath(); ctx.moveTo(cx,cy)
            ctx.arc(cx, cy, r, -0.03, 0.2); ctx.closePath()
            var g = ctx.createRadialGradient(cx,cy,r*0.1,cx,cy,r)
            g.addColorStop(0, Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.35))
            g.addColorStop(1, "transparent")
            ctx.fillStyle = g; ctx.fill()
        }
        Connections { target: root; function onCoreColorChanged() { scanner2.requestPaint() } }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 3 — Ring 8 (outermost — ghost dotted)
    // ════════════════════════════════════════════════════

    Canvas {
        id: ring8; anchors.centerIn: parent
        width: root.width * 1.0 * root.breath; height: width
        rotation: root.o8; opacity: 0.04 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 0.3; ctx.setLineDash([1,24])
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring8.requestPaint() } }
    }

    // ── Ring 7 — thin dashes ──
    Canvas {
        id: ring7; anchors.centerIn: parent
        width: root.width * 0.93 * root.breath; height: width
        rotation: root.o7; opacity: 0.05 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 0.4; ctx.setLineDash([3,20]); ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring7.requestPaint() } }
    }

    // ── Ring 6 — dotted with 24 tick marks ──
    Canvas {
        id: ring6; anchors.centerIn: parent
        width: root.width * 0.86 * root.breath; height: width
        rotation: root.o6; opacity: 0.06 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 0.5; ctx.setLineDash([2,16])
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
            // 24 tick marks
            ctx.setLineDash([]); ctx.lineWidth = 0.4
            for (var i = 0; i < 24; i++) {
                var a = i * Math.PI/12
                var inner = (i % 6 === 0) ? r - 8 : r - 4
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a)*inner, cy + Math.sin(a)*inner)
                ctx.lineTo(cx + Math.cos(a)*(r+2), cy + Math.sin(a)*(r+2))
                ctx.stroke()
            }
        }
        Connections { target: root; function onCoreColorChanged() { ring6.requestPaint() } }
    }

    // ── Ring 5 — broken arcs ──
    Canvas {
        id: ring5; anchors.centerIn: parent
        width: root.width * 0.78 * root.breath; height: width
        rotation: root.o5; opacity: 0.08 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 0.7; ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0.2,1.2); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,1.8,2.6); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,3.2,4.4); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,5.0,6.0); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring5.requestPaint() } }
    }

    // ── Ring 4 — dashed with 12 tick marks ──
    Canvas {
        id: ring4; anchors.centerIn: parent
        width: root.width * 0.70 * root.breath; height: width
        rotation: root.o4; opacity: 0.12 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 0.7; ctx.setLineDash([6,14]); ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke()
            ctx.setLineDash([]); ctx.lineWidth = 0.5
            for (var i = 0; i < 12; i++) {
                var a = i * Math.PI/6
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a)*(r-6), cy + Math.sin(a)*(r-6))
                ctx.lineTo(cx + Math.cos(a)*(r+3), cy + Math.sin(a)*(r+3))
                ctx.stroke()
            }
        }
        Connections { target: root; function onCoreColorChanged() { ring4.requestPaint() } }
    }

    // ── Ring 3 — two big arcs ──
    Canvas {
        id: ring3; anchors.centerIn: parent
        width: root.width * 0.60 * root.breath; height: width
        rotation: root.o3; opacity: 0.18 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 1.0; ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0.3,2.2); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,3.4,5.3); ctx.stroke()
            // Accent
            ctx.lineWidth = 1.8
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.5)
            ctx.beginPath(); ctx.arc(cx,cy,r,0.5,1.0); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring3.requestPaint() } }
    }

    // ── Ring 2 — triple arc ──
    Canvas {
        id: ring2; anchors.centerIn: parent
        width: root.width * 0.50 * root.breath; height: width
        rotation: root.o2; opacity: 0.25 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 1.2; ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0.1,1.4); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,2.0,3.0); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,3.8,5.5); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring2.requestPaint() } }
    }

    // ── Ring 1 (innermost orbit ring) — bright ──
    Canvas {
        id: ring1; anchors.centerIn: parent
        width: root.width * 0.40 * root.breath; height: width
        rotation: root.o1; opacity: 0.35 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor
            ctx.lineWidth = 1.5; ctx.lineCap = "round"
            ctx.beginPath(); ctx.arc(cx,cy,r,0.1,1.8); ctx.stroke()
            ctx.beginPath(); ctx.arc(cx,cy,r,3.3,5.6); ctx.stroke()
            // Bright accent
            ctx.lineWidth = 2.5
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.8)
            ctx.beginPath(); ctx.arc(cx,cy,r,0.3,0.9); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { ring1.requestPaint() } }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 4 — Inner energy arcs (3 layers)
    // ════════════════════════════════════════════════════

    Canvas {
        id: energyArcs1; anchors.centerIn: parent
        width: root.width * 0.32 * root.breath; height: width
        rotation: root.innerAngle; opacity: 0.3 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-4
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor; ctx.lineCap = "round"
            ctx.lineWidth = 1.8; ctx.beginPath(); ctx.arc(cx,cy,r,0,0.7); ctx.stroke()
            ctx.lineWidth = 1.2; ctx.beginPath(); ctx.arc(cx,cy,r*0.8,2.0,3.0); ctx.stroke()
            ctx.lineWidth = 1.5; ctx.beginPath(); ctx.arc(cx,cy,r,Math.PI+0.1,Math.PI+0.8); ctx.stroke()
            ctx.lineWidth = 1.0; ctx.beginPath(); ctx.arc(cx,cy,r*0.6,4.5,5.4); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { energyArcs1.requestPaint() } }
    }

    Canvas {
        id: energyArcs2; anchors.centerIn: parent
        width: root.width * 0.26 * root.breath; height: width
        rotation: -root.innerAngle * 0.7; opacity: 0.2 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-3
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor; ctx.lineCap = "round"
            ctx.lineWidth = 1.0; ctx.beginPath(); ctx.arc(cx,cy,r,0.5,1.2); ctx.stroke()
            ctx.lineWidth = 0.8; ctx.beginPath(); ctx.arc(cx,cy,r*0.7,3.0,3.8); ctx.stroke()
            ctx.lineWidth = 1.2; ctx.beginPath(); ctx.arc(cx,cy,r,4.0,4.8); ctx.stroke()
        }
        Connections { target: root; function onCoreColorChanged() { energyArcs2.requestPaint() } }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 5 — Core sphere (big, detailed)
    // ════════════════════════════════════════════════════

    Canvas {
        id: coreSphere; anchors.centerIn: parent
        width: root.width * 0.22 * root.breath; height: width
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2
            ctx.clearRect(0,0,width,height)
            // Main sphere gradient
            var g = ctx.createRadialGradient(cx*0.75,cy*0.7,0,cx,cy,r)
            g.addColorStop(0, Qt.rgba(1,1,1,0.95))
            g.addColorStop(0.05, Qt.rgba(root.coreColor.r*0.5+0.5,root.coreColor.g*0.5+0.5,root.coreColor.b*0.5+0.5,0.85))
            g.addColorStop(0.25, Qt.rgba(root.coreColor.r*0.4,root.coreColor.g*0.4,root.coreColor.b*0.4,0.55))
            g.addColorStop(0.6, Qt.rgba(root.coreColor.r*0.15,root.coreColor.g*0.15,root.coreColor.b*0.15,0.25))
            g.addColorStop(1, "transparent")
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.fillStyle = g; ctx.fill()
            // Inner edge ring
            ctx.beginPath(); ctx.arc(cx,cy,r*0.85,0,2*Math.PI)
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.15*root.intensity)
            ctx.lineWidth = 0.8; ctx.stroke()
            // Outer edge ring
            ctx.beginPath(); ctx.arc(cx,cy,r-1,0,2*Math.PI)
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.4*root.intensity)
            ctx.lineWidth = 1.2; ctx.stroke()
        }
        Connections {
            target: root
            function onCoreColorChanged() { coreSphere.requestPaint() }
            function onBreathChanged() { coreSphere.requestPaint() }
        }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 6 — Orbital particles (8 rings, ~35 particles)
    // ════════════════════════════════════════════════════

    // Ring 1 particles (closest, brightest, 6)
    Repeater { model: 6; Rectangle {
        property real a: index*60 + root.o1*1.5; property real pr: root.width*0.20*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-2; y: root.height/2+Math.sin(a*Math.PI/180)*pr-2
        width: 4; height: 4; radius: 2; color: root.coreColor; opacity: 0.6*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 2 particles (5)
    Repeater { model: 5; Rectangle {
        property real a: index*72+root.o2*1.1; property real pr: root.width*0.25*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-1.5; y: root.height/2+Math.sin(a*Math.PI/180)*pr-1.5
        width: 3.5; height: 3.5; radius: 1.75; color: root.coreColor; opacity: 0.5*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 3 particles (5)
    Repeater { model: 5; Rectangle {
        property real a: index*72+root.o3*0.8; property real pr: root.width*0.30*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-1.5; y: root.height/2+Math.sin(a*Math.PI/180)*pr-1.5
        width: 3; height: 3; radius: 1.5; color: root.coreColor; opacity: 0.35*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 4 particles (4)
    Repeater { model: 4; Rectangle {
        property real a: index*90+root.o4*0.7; property real pr: root.width*0.35*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-1; y: root.height/2+Math.sin(a*Math.PI/180)*pr-1
        width: 2.5; height: 2.5; radius: 1.25; color: root.coreColor; opacity: 0.25*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 5 particles (4)
    Repeater { model: 4; Rectangle {
        property real a: index*90+root.o5*0.5; property real pr: root.width*0.39*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-1; y: root.height/2+Math.sin(a*Math.PI/180)*pr-1
        width: 2; height: 2; radius: 1; color: root.coreColor; opacity: 0.18*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 6 particles (3)
    Repeater { model: 3; Rectangle {
        property real a: index*120+root.o6*0.4; property real pr: root.width*0.43*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-1; y: root.height/2+Math.sin(a*Math.PI/180)*pr-1
        width: 2; height: 2; radius: 1; color: root.coreColor; opacity: 0.12*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 7 particles (3)
    Repeater { model: 3; Rectangle {
        property real a: index*120+root.o7*0.3; property real pr: root.width*0.465*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-0.75; y: root.height/2+Math.sin(a*Math.PI/180)*pr-0.75
        width: 1.5; height: 1.5; radius: 0.75; color: root.coreColor; opacity: 0.08*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    // Ring 8 particles (outermost, 3)
    Repeater { model: 3; Rectangle {
        property real a: index*120+root.o8*0.2; property real pr: root.width*0.50*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*pr-0.75; y: root.height/2+Math.sin(a*Math.PI/180)*pr-0.75
        width: 1.5; height: 1.5; radius: 0.75; color: root.coreColor; opacity: 0.05*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}

    // ════════════════════════════════════════════════════
    //  LAYER 7 — Energy waves (always active, stronger when speaking)
    // ════════════════════════════════════════════════════

    Repeater {
        model: 4
        Rectangle {
            anchors.centerIn: parent
            width: root.width * 0.25; height: width; radius: width/2
            color: "transparent"; border.color: root.coreColor; border.width: 1
            opacity: 0; scale: 0.2

            SequentialAnimation on scale {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: index * 700 }
                NumberAnimation { from: 0.2; to: 2.2; duration: 3000; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: index * 700 }
                NumberAnimation { from: root.aiState === "speaking" ? 0.3 : 0.08; to: 0; duration: 3000; easing.type: Easing.OutCubic }
            }
        }
    }

    // ════════════════════════════════════════════════════
    //  LAYER 8 — Core center point (bright, pulsing)
    // ════════════════════════════════════════════════════

    Rectangle {
        anchors.centerIn: parent; width: 7*root.breath; height: width; radius: width/2; color: "#fff"
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: root.breathSpeed; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.95; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        }
    }

    // Small secondary glow around center
    Rectangle {
        anchors.centerIn: parent; width: 16*root.breath; height: width; radius: width/2
        color: "transparent"; border.color: root.coreColor; border.width: 1
        opacity: 0.2 * root.intensity
        Behavior on border.color { ColorAnimation { duration: 1000 } }

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.08; duration: root.breathSpeed; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.2; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        }
    }
}
