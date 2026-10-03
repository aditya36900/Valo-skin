pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

// "Spotted": which apps are using the microphone, camera or screen.
ColumnLayout {
    id: root

    spacing: Tokens.spacing.medium
    width: 300

    HudHeader {
        Layout.topMargin: Tokens.padding.medium
        title: qsTr("Spotted")
        subtitle: Spotted.any ? qsTr("Something is watching or listening") : qsTr("All clear")
        accent: Valorant.red
    }

    Repeater {
        model: [
            {
                icon: "mic",
                label: qsTr("Microphone"),
                apps: Spotted.mic
            },
            {
                icon: "videocam",
                label: qsTr("Camera"),
                apps: Spotted.camera
            },
            {
                icon: "screen_share",
                label: qsTr("Screen"),
                apps: Spotted.screen
            }
        ]

        RowLayout {
            id: row

            required property var modelData
            readonly property bool on: modelData.apps.length > 0

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium
            opacity: on ? 1 : 0.45

            MaterialIcon {
                text: row.modelData.icon
                color: row.on ? Valorant.red : Colours.palette.m3outline
                fill: row.on ? 1 : 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: row.modelData.label
                    font: Tokens.font.label.large
                    color: row.on ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.on ? row.modelData.apps.join(", ") : qsTr("Not in use")
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }
    }
}
