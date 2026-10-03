pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.valorant
import qs.services

// "Patch Notes": pending updates grouped by source, with Update all / Check now.
ColumnLayout {
    id: root

    readonly property var sections: [
        {
            title: PatchNotes.manager === "pacman" ? qsTr("System (pacman)") : qsTr("System (dnf)"),
            icon: "deployed_code",
            items: PatchNotes.system
        },
        {
            title: qsTr("AUR"),
            icon: "deployed_code_account",
            items: PatchNotes.aur
        },
        {
            title: qsTr("Flatpak"),
            icon: "apps",
            items: PatchNotes.flatpak
        },
        {
            title: qsTr("Firmware"),
            icon: "memory",
            items: PatchNotes.firmware
        }
    ].filter(s => s.items.length > 0)

    spacing: Tokens.spacing.medium
    width: 380

    HudHeader {
        Layout.topMargin: Tokens.padding.medium
        title: qsTr("Patch notes")
        subtitle: PatchNotes.checking ? qsTr("Checking for updates…") : PatchNotes.total > 0 ? qsTr("%n update(s) ready", "", PatchNotes.total) + (PatchNotes.lastChecked.getTime() ? qsTr("  //  checked %1").arg(Qt.formatTime(PatchNotes.lastChecked, "hh:mm")) : "") : qsTr("Up to date")
    }

    StyledFlickable {
        id: flick

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 360)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list

            width: flick.width
            spacing: Tokens.spacing.medium

            Repeater {
                model: root.sections

                Column {
                    id: section

                    required property var modelData

                    width: list.width
                    spacing: 2

                    RowLayout {
                        width: parent.width
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            text: section.modelData.icon
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: section.modelData.title
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.large
                        }

                        StyledText {
                            text: section.modelData.items.length
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }
                    }

                    Repeater {
                        model: section.modelData.items.slice(0, 12)

                        Item {
                            id: row

                            required property var modelData
                            required property int index

                            width: section.width
                            implicitHeight: nameText.implicitHeight + 6

                            Rectangle {
                                anchors.fill: parent
                                color: row.index % 2 ? "transparent" : Qt.alpha(Colours.palette.m3onSurface, 0.04)
                            }

                            StyledText {
                                id: nameText

                                anchors.left: parent.left
                                anchors.right: version.left
                                anchors.leftMargin: Tokens.padding.small
                                anchors.rightMargin: Tokens.spacing.small
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.name
                                elide: Text.ElideRight
                                font: Tokens.font.body.small
                            }

                            StyledText {
                                id: version

                                anchors.right: parent.right
                                anchors.rightMargin: Tokens.padding.small
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, section.width * 0.45)
                                text: row.modelData.version
                                elide: Text.ElideLeft
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.mono.small
                            }
                        }
                    }

                    StyledText {
                        visible: section.modelData.items.length > 12
                        leftPadding: Tokens.padding.small
                        text: qsTr("+ %n more", "", section.modelData.items.length - 12)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        HudIconButton {
            Layout.fillWidth: true
            primary: true
            enabled: PatchNotes.total > 0
            icon: "system_update_alt"
            text: qsTr("Update all")
            onClicked: PatchNotes.applyAll()
        }

        HudIconButton {
            enabled: !PatchNotes.checking
            icon: "refresh"
            onClicked: PatchNotes.check()
        }
    }
}
