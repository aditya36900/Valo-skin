pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.utils

// Minimized ("benched") windows as app tiles. Click to call one back to the current workspace,
// middle-click to close it. Collapses to nothing when the bench is empty.
Column {
    id: root

    readonly property int maxShown: 6
    readonly property real tileSize: Math.round(Tokens.font.body.large.pointSize * 2.2)

    spacing: Tokens.spacing.extraSmall
    visible: Bench.windows.length > 0

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Bench")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }

    Repeater {
        model: Bench.windows.slice(0, root.maxShown)

        Item {
            id: tile

            required property var modelData

            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: root.tileSize
            implicitHeight: root.tileSize

            ChamferRect {
                anchors.fill: parent
                chamfer: Valorant.chamferSmall
                topRight: 0
                bottomLeft: 0
                color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                borderColor: tileArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                borderWidth: 1
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Math.round(root.tileSize * 0.6)
                source: Icons.getAppIcon(tile.modelData.lastIpcObject?.class ?? "", "image-missing")
                asynchronous: true
            }

            MouseArea {
                id: tileArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: event => {
                    if (event.button === Qt.MiddleButton)
                        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.close({ window = "address:0x${tile.modelData.address}" })` : `closewindow address:0x${tile.modelData.address}`);
                    else
                        Bench.restore(tile.modelData);
                }
            }
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: Bench.windows.length > root.maxShown
        text: `+${Bench.windows.length - root.maxShown}`
        color: Colours.palette.m3primary
        font: Tokens.font.label.small

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Bench.restoreAll()
        }
    }
}
