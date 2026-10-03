pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Agent quick-switch ring: agents grouped by role around the screen centre.
// Arrows/Tab move, Enter/Space locks in, Esc or a click outside closes.
Item {
    id: root

    readonly property var roleOrder: ["Default", "Duelist", "Initiator", "Controller", "Sentinel"]
    readonly property var ordered: Valorant.agentIds.slice().sort((a, b) => {
        const ra = roleOrder.indexOf(Valorant.agents[a].role);
        const rb = roleOrder.indexOf(Valorant.agents[b].role);
        return ra !== rb ? ra - rb : Valorant.agents[a].name.localeCompare(Valorant.agents[b].name);
    })
    readonly property real radius: Math.min(width, height) * 0.32
    readonly property real tileSize: Math.max(48, Math.min(76, 2 * Math.PI * radius / ordered.length * 0.78))
    property int current: Math.max(0, ordered.indexOf(Valorant.agent))
    readonly property var currentInfo: Valorant.agents[ordered[current]]

    signal closed

    function lockIn(index: int): void {
        Valorant.setAgent(ordered[index]);
        closed();
    }

    function move(step: int): void {
        current = (current + step + ordered.length) % ordered.length;
        Valorant.play("tick");
    }

    function angleOf(index: int): real {
        return -Math.PI / 2 + index / ordered.length * 2 * Math.PI;
    }

    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            closed();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            lockIn(current);
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)))
            move(1);
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
            move(-1);
        else
            return;
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Valorant.navy, 0.72)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closed()
        }
    }

    // Faint guide ring
    Repeater {
        model: 96

        Rectangle {
            required property int index
            readonly property real a: index / 96 * 2 * Math.PI

            x: root.width / 2 + Math.cos(a) * root.radius - width / 2
            y: root.height / 2 + Math.sin(a) * root.radius - height / 2
            width: 2
            height: 2
            color: Qt.alpha(Valorant.white, 0.25)
        }
    }

    // Role labels at the middle of each role's arc
    Repeater {
        model: root.roleOrder.filter(r => r !== "Default")

        StyledText {
            required property string modelData
            readonly property var members: root.ordered.map((id, i) => Valorant.agents[id].role === modelData ? i : -1).filter(i => i >= 0)
            readonly property real a: members.length ? root.angleOf((members[0] + members[members.length - 1]) / 2) : 0

            x: root.width / 2 + Math.cos(a) * (root.radius + root.tileSize * 1.25) - width / 2
            y: root.height / 2 + Math.sin(a) * (root.radius + root.tileSize * 1.25) - height / 2
            text: modelData
            color: Qt.alpha(Valorant.white, 0.6)
            font: Tokens.font.label.large
        }
    }

    Repeater {
        model: root.ordered

        Item {
            id: tile

            required property string modelData
            required property int index
            readonly property var info: Valorant.agents[modelData]
            readonly property bool selected: root.current === index
            readonly property real a: root.angleOf(index)

            x: root.width / 2 + Math.cos(a) * root.radius - width / 2
            y: root.height / 2 + Math.sin(a) * root.radius - height / 2
            width: root.tileSize
            height: root.tileSize
            scale: selected ? 1.25 : 1
            z: selected ? 1 : 0

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            ChamferRect {
                anchors.fill: parent
                color: Qt.alpha(tile.info.accent, tile.selected ? 0.4 : 0.14)
                borderColor: tile.selected ? tile.info.accent : Qt.alpha(tile.info.accent, 0.5)
                borderWidth: tile.selected ? 2 : 1
                topRight: 0
                bottomLeft: 0
            }

            StyledText {
                anchors.centerIn: parent
                text: tile.info.name.replace(/[^A-Za-z]/g, "").slice(0, 2)
                color: tile.info.accent
                font: Tokens.font.headline.small
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = tile.index
                onClicked: root.lockIn(tile.index)
            }
        }
    }

    // Centre readout
    Column {
        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Select agent")
            color: Qt.alpha(Valorant.white, 0.7)
            font: Tokens.font.label.large
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentInfo.name
            color: root.currentInfo.accent
            font: Tokens.font.headline.builders.large.scale(2).build()
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.currentInfo.role + (root.ordered[root.current] === Valorant.agent ? qsTr("  ·  locked in") : "")
            color: Valorant.white
            font: Tokens.font.label.medium
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: Tokens.spacing.medium
            text: qsTr("← → select   ⏎ lock in   esc close")
            color: Qt.alpha(Valorant.white, 0.45)
            font: Tokens.font.label.small
        }
    }
}
