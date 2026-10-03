pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

// Valorant round-timer styled clock: stacked HH/MM with a bar that drains every minute
// and turns red for the final ten seconds, like the round clock before the buy phase ends.
Item {
    id: root

    readonly property int secondsLeft: 60 - Time.seconds
    readonly property bool critical: secondsLeft <= 10
    readonly property color timerColour: critical ? Valorant.red : Colours.palette.m3primary
    readonly property int padding: Tokens.padding.small

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight + padding * 2 + Valorant.chamferSmall

    ChamferRect {
        anchors.fill: parent
        color: Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer : "transparent"
        borderColor: Colours.palette.m3outlineVariant
        borderWidth: Config.bar.clock.background ? 0 : 1
        topRight: 0
        bottomLeft: 0
    }

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.padding + Valorant.chamferSmall / 2
        spacing: 0

        Loader {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 2
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ddd")
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            font: Tokens.font.title.builders.large.scale(0.95).build()
            color: Colours.palette.m3onSurface
        }

        // Separator ticks, standing in for the colon
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -2
            Layout.bottomMargin: -2
            spacing: 3

            Repeater {
                model: 2

                StyledRect {
                    implicitWidth: 3
                    implicitHeight: 3
                    color: root.timerColour
                    opacity: root.critical && Time.seconds % 2 ? 0.3 : 1
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            font: Tokens.font.title.builders.large.scale(0.95).build()
            color: root.critical ? Valorant.red : Colours.palette.m3onSurface
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Draining round bar
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.extraSmall
            implicitWidth: Tokens.sizes.bar.innerWidth - root.padding * 2
            implicitHeight: 3

            StyledRect {
                anchors.fill: parent
                color: Qt.alpha(root.timerColour, 0.2)
            }

            StyledRect {
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                width: parent.width * root.secondsLeft / 60
                color: root.timerColour

                Behavior on width {
                    Anim {
                        type: Anim.StandardSmall
                    }
                }
            }
        }
    }
}
