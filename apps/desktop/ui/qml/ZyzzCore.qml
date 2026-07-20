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
        switch (aiState) { case "listening": return 0.95; case "thinking": return 0.8; case "speaking": return 0.9; case "error": return 1.0; default: return 0.5 }
    }
    property real breathSpeed: {
        switch (aiState) { case "listening": return 1600; case "thinking": return 800; case "speaking": return 1200; case "error": return 400; default: return 3200 }
    }
    Behavior on coreColor { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
    Behavior on intensity { NumberAnimation { duration: 1000 } }

    property real breath: 1.0
    SequentialAnimation on breath {
        loops: Animation.Infinite
        NumberAnimation { to: 1.05; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.96; duration: root.breathSpeed; easing.type: Easing.InOutSine }
    }

    // Orbit angles
    property real o1: 0; property real o2: 0; property real o3: 0; property real o4: 0; property real o5: 0
    property real scanAngle: 0; property real innerAngle: 0
    NumberAnimation on o1 { from:0; to:360; duration:10000; loops:Animation.Infinite }
    NumberAnimation on o2 { from:360; to:0; duration:14000; loops:Animation.Infinite }
    NumberAnimation on o3 { from:0; to:360; duration:20000; loops:Animation.Infinite }
    NumberAnimation on o4 { from:360; to:0; duration:28000; loops:Animation.Infinite }
    NumberAnimation on o5 { from:0; to:360; duration:38000; loops:Animation.Infinite }
    NumberAnimation on scanAngle { from:0; to:360; duration:3000; loops:Animation.Infinite }
    NumberAnimation on innerAngle { from:0; to:360; duration:5000; loops:Animation.Infinite }

    // ── Outer ambient glow ──
    Canvas {
        id: outerGlow; anchors.centerIn: parent; width: root.width * 1.6; height: width
        opacity: 0.3 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2;
            ctx.clearRect(0,0,width,height);
            var g = ctx.createRadialGradient(cx,cy,0,cx,cy,cx);
            g.addColorStop(0, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.15));
            g.addColorStop(0.4, Qt.rgba(root.coreColor.r, root.coreColor.g, root.coreColor.b, 0.04));
            g.addColorStop(1, "transparent");
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height);
        }
        Connections { target: root; function onCoreColorChanged() { outerGlow.requestPaint() } }
    }

    // ── Scanner sweep ──
    Canvas {
        id: scanner; anchors.centerIn: parent
        width: root.width * 0.9 * root.breath; height: width
        rotation: root.scanAngle
        opacity: 0.12 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2;
            ctx.clearRect(0,0,width,height);
            ctx.beginPath(); ctx.moveTo(cx,cy);
            ctx.arc(cx, cy, r, -0.05, 0.35); ctx.closePath();
            var g = ctx.createRadialGradient(cx,cy,r*0.2,cx,cy,r);
            g.addColorStop(0, Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.4));
            g.addColorStop(1, "transparent");
            ctx.fillStyle = g; ctx.fill();
        }
        Connections { target: root; function onCoreColorChanged() { scanner.requestPaint() } }
    }

    // ── Ring 5 (outermost) — dotted ──
    Canvas {
        anchors.centerIn: parent; width: root.width * 1.1 * root.breath; height: width
        rotation: root.o5; opacity: 0.06 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.5; ctx.setLineDash([2,18]);
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke();
        }
        Connections { target: root; function onCoreColorChanged() { parent.children[4].requestPaint() } }
    }

    // ── Ring 4 ──
    Canvas {
        id: ring4; anchors.centerIn: parent; width: root.width * 0.95 * root.breath; height: width
        rotation: root.o4; opacity: 0.1 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.6; ctx.setLineDash([6,20]); ctx.lineCap = "round";
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.stroke();
            // Tick marks
            ctx.setLineDash([]); ctx.lineWidth = 0.5;
            for (var i = 0; i < 12; i++) {
                var a = i * Math.PI/6;
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a)*(r-4), cy + Math.sin(a)*(r-4));
                ctx.lineTo(cx + Math.cos(a)*(r+2), cy + Math.sin(a)*(r+2));
                ctx.stroke();
            }
        }
        Connections { target: root; function onCoreColorChanged() { ring4.requestPaint() } }
    }

    // ── Ring 3 ──
    Canvas {
        id: ring3; anchors.centerIn: parent; width: root.width * 0.8 * root.breath; height: width
        rotation: root.o3; opacity: 0.18 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 0.8; ctx.lineCap = "round";
            ctx.beginPath(); ctx.arc(cx,cy,r,0.4,2.0); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx,cy,r,3.0,4.8); ctx.stroke();
        }
        Connections { target: root; function onCoreColorChanged() { ring3.requestPaint() } }
    }

    // ── Ring 2 ──
    Canvas {
        id: ring2; anchors.centerIn: parent; width: root.width * 0.65 * root.breath; height: width
        rotation: root.o2; opacity: 0.28 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1.0; ctx.lineCap = "round";
            ctx.beginPath(); ctx.arc(cx,cy,r,0.2,1.5); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx,cy,r,2.0,2.8); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx,cy,r,3.8,5.6); ctx.stroke();
        }
        Connections { target: root; function onCoreColorChanged() { ring2.requestPaint() } }
    }

    // ── Ring 1 (innermost) ──
    Canvas {
        id: ring1; anchors.centerIn: parent; width: root.width * 0.52 * root.breath; height: width
        rotation: root.o1; opacity: 0.38 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-2;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineWidth = 1.2; ctx.lineCap = "round";
            // Main arcs
            ctx.beginPath(); ctx.arc(cx,cy,r,0.1,1.6); ctx.stroke();
            ctx.beginPath(); ctx.arc(cx,cy,r,3.5,5.4); ctx.stroke();
            // Bright accent arc
            ctx.lineWidth = 2.0;
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.7);
            ctx.beginPath(); ctx.arc(cx,cy,r,0.3,0.9); ctx.stroke();
        }
        Connections { target: root; function onCoreColorChanged() { ring1.requestPaint() } }
    }

    // ── Inner energy arcs ──
    Canvas {
        id: energyArcs; anchors.centerIn: parent; width: root.width * 0.4 * root.breath; height: width
        rotation: root.innerAngle; opacity: 0.25 * root.intensity
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2-4;
            ctx.clearRect(0,0,width,height); ctx.strokeStyle = root.coreColor;
            ctx.lineCap = "round";
            ctx.lineWidth = 1.5; ctx.beginPath(); ctx.arc(cx,cy,r,0,0.6); ctx.stroke();
            ctx.lineWidth = 1.0; ctx.beginPath(); ctx.arc(cx,cy,r*0.7,2.2,3.0); ctx.stroke();
            ctx.lineWidth = 1.3; ctx.beginPath(); ctx.arc(cx,cy,r,Math.PI+0.1,Math.PI+0.7); ctx.stroke();
            ctx.lineWidth = 0.8; ctx.beginPath(); ctx.arc(cx,cy,r*0.5,4.5,5.2); ctx.stroke();
        }
        Connections { target: root; function onCoreColorChanged() { energyArcs.requestPaint() } }
    }

    // ── Core sphere ──
    Canvas {
        id: coreSphere; anchors.centerIn: parent
        width: root.width * 0.32 * root.breath; height: width
        onPaint: {
            var ctx = getContext("2d"); var cx = width/2, cy = height/2, r = width/2;
            ctx.clearRect(0,0,width,height);
            var g = ctx.createRadialGradient(cx*0.8,cy*0.75,0,cx,cy,r);
            g.addColorStop(0, Qt.rgba(1,1,1,0.9));
            g.addColorStop(0.06, Qt.rgba(root.coreColor.r*0.5+0.5,root.coreColor.g*0.5+0.5,root.coreColor.b*0.5+0.5,0.8));
            g.addColorStop(0.3, Qt.rgba(root.coreColor.r*0.3,root.coreColor.g*0.3,root.coreColor.b*0.3,0.5));
            g.addColorStop(0.7, Qt.rgba(root.coreColor.r*0.1,root.coreColor.g*0.1,root.coreColor.b*0.1,0.2));
            g.addColorStop(1, "transparent");
            ctx.beginPath(); ctx.arc(cx,cy,r,0,2*Math.PI); ctx.fillStyle = g; ctx.fill();
            // Edge ring
            ctx.beginPath(); ctx.arc(cx,cy,r-1,0,2*Math.PI);
            ctx.strokeStyle = Qt.rgba(root.coreColor.r,root.coreColor.g,root.coreColor.b,0.35*root.intensity);
            ctx.lineWidth = 1; ctx.stroke();
        }
        Connections {
            target: root
            function onCoreColorChanged() { coreSphere.requestPaint() }
            function onBreathChanged() { coreSphere.requestPaint() }
        }
    }

    // ── Orbital particles — 5 rings ──
    Repeater { model: 5; Rectangle {
        property real a: index*72 + root.o1*1.4; property real r: root.width*0.26*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*r-1.5; y: root.height/2+Math.sin(a*Math.PI/180)*r-1.5
        width: 3; height: 3; radius: 1.5; color: root.coreColor; opacity: 0.55*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    Repeater { model: 4; Rectangle {
        property real a: index*90+root.o2*0.9; property real r: root.width*0.325*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*r-1; y: root.height/2+Math.sin(a*Math.PI/180)*r-1
        width: 2.5; height: 2.5; radius: 1.25; color: root.coreColor; opacity: 0.4*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    Repeater { model: 3; Rectangle {
        property real a: index*120+root.o3*0.7; property real r: root.width*0.4*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*r-1; y: root.height/2+Math.sin(a*Math.PI/180)*r-1
        width: 2; height: 2; radius: 1; color: root.coreColor; opacity: 0.25*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    Repeater { model: 3; Rectangle {
        property real a: index*120+root.o4*0.5; property real r: root.width*0.475*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*r-0.75; y: root.height/2+Math.sin(a*Math.PI/180)*r-0.75
        width: 1.5; height: 1.5; radius: 0.75; color: root.coreColor; opacity: 0.15*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}
    Repeater { model: 2; Rectangle {
        property real a: index*180+root.o5*0.3; property real r: root.width*0.55*root.breath
        x: root.width/2+Math.cos(a*Math.PI/180)*r-0.75; y: root.height/2+Math.sin(a*Math.PI/180)*r-0.75
        width: 1.5; height: 1.5; radius: 0.75; color: root.coreColor; opacity: 0.08*root.intensity
        Behavior on color { ColorAnimation { duration: 1000 } }
    }}

    // ── Energy waves (speaking state) ──
    Repeater {
        model: 3
        Rectangle {
            anchors.centerIn: parent
            width: root.width * 0.35; height: width; radius: width/2
            color: "transparent"; border.color: root.coreColor; border.width: 1
            visible: root.aiState === "speaking"
            opacity: 0; scale: 0.3

            SequentialAnimation on scale {
                running: root.aiState === "speaking"; loops: Animation.Infinite
                PauseAnimation { duration: index * 500 }
                NumberAnimation { from: 0.3; to: 1.8; duration: 2000; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: root.aiState === "speaking"; loops: Animation.Infinite
                PauseAnimation { duration: index * 500 }
                NumberAnimation { from: 0.25; to: 0; duration: 2000; easing.type: Easing.OutCubic }
            }
        }
    }

    // ── Core center point ──
    Rectangle {
        anchors.centerIn: parent; width: 5*root.breath; height: width; radius: width/2; color: "#fff"
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.5; duration: root.breathSpeed; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.95; duration: root.breathSpeed; easing.type: Easing.InOutSine }
        }
    }
}
