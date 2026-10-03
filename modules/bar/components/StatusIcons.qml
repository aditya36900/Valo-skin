pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.utils
import qs.modules.bar.components.status

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        if (entry.id === "privacy")
            return !Spotted.any;
        if (entry.id === "phone")
            return !Uplink.installed;
        if (entry.id === "updates")
            return PatchNotes.total === 0;
        return false;
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: iconColumn.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: iconColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.medium

        spacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                values: Valorant.statusEntries(root.Config.bar.statusIcons.values)
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        charge: Audio.muted ? 0 : Audio.volume

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout
                        charge: Audio.sourceMuted ? 0 : Audio.sourceVolume

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: root.colour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        charge: Nmcli.activeEthernet ? 1 : Nmcli.active ? (Nmcli.active.strength ?? 0) / 100 : 0

                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "privacy"
                    delegate: EntryWrapper {
                        Item {
                            visible: Spotted.any
                            implicitWidth: visible ? privacyColumn.implicitWidth : 0
                            implicitHeight: visible ? privacyColumn.implicitHeight : 0

                            Column {
                                id: privacyColumn

                                spacing: 2

                                Repeater {
                                    model: [
                                        {
                                            on: Spotted.mic.length > 0,
                                            icon: "mic"
                                        },
                                        {
                                            on: Spotted.camera.length > 0,
                                            icon: "videocam"
                                        },
                                        {
                                            on: Spotted.screen.length > 0,
                                            icon: "screen_share"
                                        }
                                    ]

                                    MaterialIcon {
                                        required property var modelData

                                        anchors.horizontalCenter: parent.horizontalCenter
                                        visible: modelData.on
                                        text: modelData.icon
                                        color: Valorant.red
                                        fill: 1
                                        fontStyle: Tokens.font.icon.small

                                        SequentialAnimation on opacity {
                                            running: Spotted.any
                                            loops: Animation.Infinite

                                            NumberAnimation {
                                                to: 0.45
                                                duration: 700
                                            }
                                            NumberAnimation {
                                                to: 1
                                                duration: 700
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "phone"
                    delegate: EntryWrapper {
                        charge: Uplink.phone && Uplink.phone.battery >= 0 ? Uplink.phone.battery / 100 : -1

                        Item {
                            visible: Uplink.installed
                            implicitWidth: visible ? phoneIcon.implicitWidth : 0
                            implicitHeight: visible ? phoneIcon.implicitHeight : 0

                            MaterialIcon {
                                id: phoneIcon

                                animate: true
                                text: !Uplink.phone ? "phonelink_off" : Uplink.phone.charging ? "mobile_charge" : "smartphone"
                                color: Uplink.phone ? root.colour : Colours.palette.m3outline
                                fill: Uplink.phone ? 1 : 0
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "updates"
                    delegate: EntryWrapper {
                        Item {
                            visible: PatchNotes.total > 0
                            implicitWidth: visible ? updIcon.implicitWidth : 0
                            implicitHeight: visible ? updIcon.implicitHeight : 0

                            MaterialIcon {
                                id: updIcon

                                text: "system_update_alt"
                                color: root.colour
                            }

                            StyledRect {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: -6
                                anchors.topMargin: -4
                                implicitWidth: Math.max(implicitHeight, countText.implicitWidth + 4)
                                implicitHeight: countText.implicitHeight
                                radius: 0
                                color: Valorant.red

                                StyledText {
                                    id: countText

                                    anchors.centerIn: parent
                                    text: PatchNotes.total > 99 ? "99+" : PatchNotes.total
                                    color: Valorant.white
                                    font: Tokens.font.label.builders.small.scale(0.75).build()
                                }
                            }
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        charge: UPower.displayDevice.isLaptopBattery ? UPower.displayDevice.percentage : -1

                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        id: entry

        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        // Valorant ability slot: chamfered frame, keybind hint and charge pips (charge < 0 hides them)
        property real charge: -1
        readonly property bool slotted: Valorant.hudOn("abilitySlots") && modelData.id !== "lockStatus" && present
        readonly property real slotSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small
        readonly property real pipsHeight: charge >= 0 ? 5 : 0
        property ChamferRect frame: ChamferRect {
            parent: entry
            anchors.fill: parent
            visible: entry.slotted
            color: Colours.tPalette.m3surfaceContainerHigh
            borderColor: Colours.palette.m3outlineVariant
            borderWidth: 1
            topRight: 0
            bottomLeft: 0
        }
        property StyledText keyHint: StyledText {
            parent: entry
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 4
            anchors.topMargin: 3
            visible: entry.slotted
            text: ["C", "Q", "E", "X", "F", "Z", "V"][entry.index % 7]
            font: Tokens.font.label.builders.small.scale(0.6).build()
            color: Colours.palette.m3outline
        }
        property ChargePips pips: ChargePips {
            parent: entry
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            visible: entry.slotted && entry.charge >= 0
            value: entry.charge
            count: 4
            spacing: 1.5
            pipLength: (entry.slotSize - 8 - spacing * 3) / 4
            pipThickness: 3
            fillColor: entry.charge > 0.2 ? Colours.palette.m3primary : Valorant.red
        }
        property real topGap: present && index !== root.firstPresent ? margin : 0
        property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()
        // Centres the icon inside the slot, leaving room for the pips underneath
        property Item iconBox: Item {
            parent: entry
            x: (entry.width - width) / 2
            y: entry.slotted ? (entry.height - entry.pipsHeight - height) / 2 - (entry.pipsHeight > 0 ? 1 : 0) : 0
            implicitWidth: entry.item?.implicitWidth ?? 0
            implicitHeight: entry.item?.implicitHeight ?? 0
            children: entry.item
        }

        Layout.topMargin: Math.round(topGap)
        Layout.bottomMargin: Math.round(bottomGap)
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: slotted ? slotSize : item?.implicitWidth ?? 0
        implicitHeight: slotted ? Math.max(slotSize, (item?.implicitHeight ?? 0) + pipsHeight + 12) : item?.implicitHeight ?? 0

        children: [frame, keyHint, pips, iconBox]

        Behavior on topGap {
            Anim {
                type: Anim.SlowEffects
            }
        }

        Behavior on bottomGap {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }
}
