pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Agent lock-in flourish: jittering accent bars over the screen and the agent's name, ~1 s.
// Purely visual (no input handling); plays on Valorant.agentLockedIn when fx.glitch is on,
// and once per session as a "Welcome back" banner with the player's name.
Item {
    id: root

    property string agentName
    property string caption: qsTr("Agent locked in")
    property real hold: 1
    property color accent: Valorant.accent
    property int seed

    // Cheap deterministic noise in [0, 1)
    function hash(x: real): real {
        const v = Math.sin(x) * 43758.5453;
        return v - Math.floor(v);
    }

    function play(): void {
        if (!Valorant.glitch)
            return;
        caption = qsTr("Agent locked in");
        agentName = Valorant.agentInfo.name;
        hold = 1;
        anim.restart();
    }

    function playWelcome(): void {
        if (!Valorant.glitch || !Valorant.welcomeBanner || !Valorant.playerName)
            return;
        caption = qsTr("Welcome back, %1").arg(Valorant.playerTitle);
        agentName = Valorant.playerName;
        hold = 3;
        anim.restart();
    }

    anchors.fill: parent
    visible: anim.running
    opacity: Math.min(1, Valorant.fxIntensity)

    Connections {
        function onAgentLockedIn(): void {
            root.play();
        }

        target: Valorant
    }

    // Welcome banner once per session (survives shell reloads)
    PersistentProperties {
        id: session

        property bool welcomed

        reloadableId: "valoWelcome"
    }

    Timer {
        running: !session.welcomed
        interval: 1800
        onTriggered: {
            session.welcomed = true;
            root.playWelcome();
        }
    }

    // Horizontal glitch slices, re-randomised every frame tick while playing
    Repeater {
        model: 9

        StyledRect {
            required property int index
            readonly property real r1: root.hash((root.seed + 1) * (index + 3) * 12.9898)
            readonly property real r2: root.hash((root.seed + 7) * (index + 1) * 78.233)

            x: (r1 - 0.5) * root.width * 0.15
            y: r2 * root.height
            width: root.width * (0.35 + r1 * 0.65)
            height: 2 + r2 * 18
            color: index % 3 === 0 ? Valorant.red : index % 3 === 1 ? root.accent : Qt.alpha(Valorant.white, 0.6)
            opacity: glitchPhase.opacity * (0.25 + r1 * 0.5)
        }
    }

    // Lock-in banner
    Item {
        id: banner

        anchors.centerIn: parent
        implicitWidth: name.implicitWidth + 120
        implicitHeight: name.implicitHeight + 40
        opacity: 0

        ChamferRect {
            anchors.fill: parent
            color: Qt.alpha(Valorant.navy, 0.85)
            borderColor: root.accent
            borderWidth: 2
            chamfer: 18
            topRight: 0
            bottomLeft: 0
        }

        StyledText {
            id: lockedIn

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: name.top
            anchors.bottomMargin: -6
            text: root.caption
            color: Valorant.white
            font: Tokens.font.label.large
        }

        StyledText {
            id: name

            anchors.centerIn: parent
            anchors.verticalCenterOffset: 8
            text: root.agentName
            color: root.accent
            font: Tokens.font.headline.builders.large.scale(2.4).build()
        }

        // Chromatic offset copies for the glitch frames
        StyledText {
            x: name.x + 4
            y: name.y
            text: root.agentName
            color: Valorant.red
            font: name.font
            opacity: glitchPhase.opacity * 0.6
        }

        StyledText {
            x: name.x - 4
            y: name.y
            text: root.agentName
            color: Valorant.teal
            font: name.font
            opacity: glitchPhase.opacity * 0.4
        }
    }

    QtObject {
        id: glitchPhase

        property real opacity
    }

    Timer {
        interval: 45
        repeat: true
        running: anim.running
        onTriggered: root.seed = (root.seed + 1) % 997
    }

    SequentialAnimation {
        id: anim

        ParallelAnimation {
            NumberAnimation {
                target: glitchPhase
                property: "opacity"
                from: 0
                to: 1
                duration: 80
            }
            NumberAnimation {
                target: banner
                property: "opacity"
                from: 0
                to: 1
                duration: 120
            }
            NumberAnimation {
                target: banner
                property: "scale"
                from: 1.25
                to: 1
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        PauseAnimation {
            duration: 160
        }
        NumberAnimation {
            target: glitchPhase
            property: "opacity"
            to: 0
            duration: 200
        }
        PauseAnimation {
            duration: 450 * root.hold * Math.max(0.5, Valorant.fxIntensity)
        }
        NumberAnimation {
            target: banner
            property: "opacity"
            to: 0
            duration: 260
        }
    }
}
