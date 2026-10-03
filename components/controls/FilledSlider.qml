import "../effects"
import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

Slider {
    id: root

    required property string icon
    property real oldValue
    property bool initialized
    // Valorant: render as an ability charge meter of stacked pips with a chamfered icon slot
    readonly property bool charge: Valorant.hudOn("chargeOsd")
    readonly property int pipCount: Math.max(4, Math.floor(availableHeight / 12))

    orientation: Qt.Vertical

    background: StyledRect {
        color: root.charge ? "transparent" : Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        Column {
            anchors.fill: parent
            anchors.topMargin: root.handle.height + 4
            visible: root.charge
            spacing: 3

            Repeater {
                model: root.pipCount

                ChamferRect {
                    required property int index
                    readonly property real level: (root.pipCount - index) / root.pipCount

                    width: parent.width
                    height: (parent.height - parent.spacing * (root.pipCount - 1)) / root.pipCount
                    chamfer: 0
                    topRight: height * 0.6
                    bottomLeft: height * 0.6
                    color: level <= root.position + 0.001 ? (root.position > 0.999 ? Valorant.gold : Colours.palette.m3primary) : Qt.alpha(Colours.palette.m3onSurface, 0.1)
                }
            }
        }

        StyledRect {
            visible: !root.charge
            anchors.left: parent.left
            anchors.right: parent.right

            y: root.handle.y
            implicitHeight: parent.height - y

            color: Colours.palette.m3secondary
            radius: parent.radius
        }
    }

    handle: Item {
        id: handle

        property alias moving: icon.moving

        // Charge mode pins the icon slot on top of the meter
        y: root.charge ? 0 : root.visualPosition * (root.availableHeight - height)
        implicitWidth: root.width
        implicitHeight: root.width

        Elevation {
            anchors.fill: parent
            radius: rect.radius
            level: handleInteraction.containsMouse ? 2 : 1
            visible: !root.charge
        }

        ChamferRect {
            anchors.fill: parent
            visible: root.charge
            color: Colours.palette.m3surfaceContainerHighest
            borderColor: root.position > 0.999 ? Valorant.gold : Colours.palette.m3primary
            borderWidth: 1.5
            topRight: 0
            bottomLeft: 0
        }

        StyledRect {
            id: rect

            anchors.fill: parent

            color: root.charge ? "transparent" : Colours.palette.m3inverseSurface
            radius: Tokens.rounding.full

            MouseArea {
                id: handleInteraction

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            MaterialIcon {
                id: icon

                property bool moving

                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: moving ? Math.round(root.value * 100) : root.icon
                color: root.charge ? Colours.palette.m3onSurface : Colours.palette.m3inverseOnSurface
                font: moving ? Tokens.font.body.small : Tokens.font.icon.medium

                Behavior on moving {
                    SequentialAnimation {
                        Anim {
                            target: icon
                            property: "scale"
                            to: 0.3
                            duration: Tokens.anim.durations.small / 2
                            easing: Tokens.anim.standardAccel
                        }
                        PropertyAction {}
                        Anim {
                            target: icon
                            property: "scale"
                            to: 1
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardDecel
                        }
                    }
                }
            }
        }
    }

    onPressedChanged: handle.moving = pressed

    onValueChanged: {
        if (!initialized) {
            initialized = true;
            return;
        }
        if (Math.abs(value - oldValue) < 0.01)
            return;
        oldValue = value;
        handle.moving = true;
        stateChangeDelay.restart();
    }

    Timer {
        id: stateChangeDelay

        interval: 500
        onTriggered: {
            if (!root.pressed)
                handle.moving = false;
        }
    }

    Behavior on value {
        Anim {
            type: Anim.StandardLarge
        }
    }
}
