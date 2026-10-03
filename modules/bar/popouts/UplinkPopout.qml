pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

// "Uplink": phone card (battery, signal) and quick actions through KDE Connect.
ColumnLayout {
    id: root

    readonly property var phone: Uplink.phone

    spacing: Tokens.spacing.medium
    width: 340

    Component.onCompleted: Uplink.refresh()

    HudHeader {
        Layout.topMargin: Tokens.padding.medium
        title: qsTr("Uplink")
        subtitle: root.phone ? qsTr("Phone link // %1").arg(root.phone.name) : Uplink.running ? qsTr("Phone link // no phone in range") : qsTr("Phone link // KDE Connect offline")
    }

    // Phone card
    Item {
        visible: !!root.phone
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? card.implicitHeight + Tokens.padding.medium * 2 : 0

        HudCard {
            color: Qt.alpha(Colours.palette.m3primary, 0.1)
        }

        RowLayout {
            id: card

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.large

            MaterialIcon {
                text: root.phone?.type === "tablet" ? "tablet_android" : "smartphone"
                color: Colours.palette.m3primary
                fill: 1
                fontStyle: Tokens.font.icon.builders.large.scale(1.6).build()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: root.phone?.name ?? ""
                    elide: Text.ElideRight
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                }

                // Battery
                RowLayout {
                    spacing: Tokens.spacing.small
                    visible: (root.phone?.battery ?? -1) >= 0

                    MaterialIcon {
                        text: root.phone?.charging ? "battery_charging_full" : "battery_full"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    ChargePips {
                        count: 5
                        value: (root.phone?.battery ?? 0) / 100
                        pipLength: 10
                        pipThickness: 5
                        fillColor: (root.phone?.battery ?? 0) > 20 ? Colours.palette.m3primary : Valorant.red
                    }

                    StyledText {
                        text: `${root.phone?.battery ?? 0}%${root.phone?.charging ? qsTr("  charging") : ""}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                // Signal
                RowLayout {
                    spacing: Tokens.spacing.small
                    visible: (root.phone?.signal ?? -1) >= 0

                    MaterialIcon {
                        text: "signal_cellular_alt"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    ChargePips {
                        count: 4
                        value: (root.phone?.signal ?? 0) / 4
                        pipLength: 10
                        pipThickness: 5
                    }

                    StyledText {
                        text: root.phone?.network ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    // Actions
    GridLayout {
        visible: !!root.phone
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Tokens.spacing.small
        columnSpacing: Tokens.spacing.small

        Repeater {
            model: [
                {
                    icon: "ring_volume",
                    label: qsTr("Ring"),
                    run: () => Uplink.ring()
                },
                {
                    icon: "screenshot_monitor",
                    label: qsTr("Screenshot"),
                    run: () => Uplink.sendScreenshot()
                },
                {
                    icon: "content_paste_go",
                    label: qsTr("Clipboard"),
                    run: () => Uplink.sendClipboard()
                },
                {
                    icon: "upload_file",
                    label: qsTr("Send file"),
                    run: () => Uplink.pickAndShare()
                },
                {
                    icon: "folder_open",
                    label: qsTr("Browse"),
                    run: () => Uplink.browse()
                },
                {
                    icon: "sms",
                    label: qsTr("Messages"),
                    run: () => Uplink.openSms()
                }
            ]

            Item {
                id: action

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: actionCol.implicitHeight + Tokens.padding.medium * 2

                ChamferRect {
                    anchors.fill: parent
                    chamfer: Valorant.chamferSmall
                    topRight: 0
                    bottomLeft: 0
                    color: actionArea.containsMouse ? Qt.alpha(Colours.palette.m3primary, 0.16) : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                    borderColor: actionArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                    borderWidth: 1
                }

                Column {
                    id: actionCol

                    anchors.centerIn: parent
                    spacing: 2

                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.icon
                        color: actionArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: action.modelData.label
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                MouseArea {
                    id: actionArea

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !Uplink.busy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: action.modelData.run()
                }
            }
        }
    }

    // Known but unpaired / out of range devices
    Repeater {
        model: Uplink.devices.filter(d => d.id !== root.phone?.id)

        RowLayout {
            id: other

            required property var modelData

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "smartphone"
                color: Colours.palette.m3outline
            }

            StyledText {
                Layout.fillWidth: true
                text: other.modelData.name
                elide: Text.ElideRight
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                visible: !other.modelData.reachable
                text: qsTr("Out of range")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            HudIconButton {
                visible: other.modelData.reachable && !other.modelData.paired
                icon: "link"
                text: qsTr("Pair")
                onClicked: Uplink.pair(other.modelData.id)
            }
        }
    }

    // Setup hints
    StyledText {
        visible: !root.phone
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        text: !Uplink.installed ? qsTr("Install KDE Connect on this PC (sudo dnf install kdeconnectd) and the KDE Connect app on your phone, then pair them on the same Wi-Fi.") : qsTr("Open the KDE Connect app on your phone (same Wi-Fi) and pair it. Phone notifications and calls then show up here as banners.")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            visible: !!root.phone
            text: qsTr("Notifications and calls arrive as uplink banners")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            visible: !root.phone
        }

        HudIconButton {
            icon: "refresh"
            onClicked: Uplink.refresh()
        }

        HudIconButton {
            visible: Uplink.installed
            icon: "settings"
            onClicked: Uplink.openApp()
        }
    }
}
