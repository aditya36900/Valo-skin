pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.valorant
import qs.services

// "Night Ops" utilities card: blue-light filter switch, schedule mode and warmth.
StyledRect {
    id: root

    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.extraLargeIncreased

    implicitHeight: nonAnimHeight
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Item {
                implicitWidth: implicitHeight
                implicitHeight: icon.implicitHeight + Tokens.padding.large

                ChamferRect {
                    anchors.fill: parent
                    chamfer: Valorant.chamferSmall
                    topRight: 0
                    bottomLeft: 0
                    color: NightOps.active ? Valorant.gold : Colours.palette.m3secondaryContainer
                }

                MaterialIcon {
                    id: icon

                    anchors.centerIn: parent
                    text: "nightlight"
                    fill: NightOps.active ? 1 : 0
                    color: NightOps.active ? Valorant.navy : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: qsTr("Night Ops")
                    font: Tokens.font.body.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    text: {
                        if (!NightOps.available)
                            return qsTr("Install hyprsunset to use this");
                        const sched = NightOps.mode === "sun" ? qsTr("sunset to sunrise") : NightOps.mode === "schedule" ? `${NightOps.start}–${NightOps.end}` : "";
                        if (NightOps.active)
                            return qsTr("Engaged // %1K").arg(NightOps.temperature) + (sched ? `  //  ${sched}` : "");
                        return sched ? qsTr("Standby // %1").arg(sched) : qsTr("Off");
                    }
                }
            }

            StyledSwitch {
                checked: NightOps.active
                onToggled: NightOps.toggle()
            }
        }

        // Mode chips
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: [
                    {
                        id: "off",
                        label: qsTr("Off")
                    },
                    {
                        id: "on",
                        label: qsTr("On")
                    },
                    {
                        id: "schedule",
                        label: qsTr("Schedule")
                    },
                    {
                        id: "sun",
                        label: qsTr("Sun")
                    }
                ]

                Item {
                    id: chip

                    required property var modelData
                    readonly property bool selected: NightOps.mode === modelData.id

                    Layout.fillWidth: true
                    implicitHeight: chipLabel.implicitHeight + Tokens.padding.small * 2

                    ChamferRect {
                        anchors.fill: parent
                        chamfer: Valorant.chamferSmall
                        topRight: 0
                        bottomLeft: 0
                        color: chip.selected ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    }

                    StyledText {
                        id: chipLabel

                        anchors.centerIn: parent
                        text: chip.modelData.label
                        color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NightOps.setMode(chip.modelData.id)
                    }
                }
            }
        }

        // Warmth: 6500K (neutral) on the left to 2500K (warm) on the right
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "wb_sunny"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            StyledSlider {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.large * 1.5
                value: (6500 - NightOps.temperature) / 4000
                fgColour: Valorant.gold
                onInteraction: v => NightOps.setTemperature(6500 - v * 4000)
            }

            StyledText {
                text: `${NightOps.temperature}K`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.mono.small
            }
        }
    }
}
