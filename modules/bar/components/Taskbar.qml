pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.utils

// Windows-style taskbar in the vertical bar: pinned apps and every open window.
//   click: focus a window / minimize the active one / restore a minimized one / launch a pin
//   middle-click: close   right-click: pin or unpin   hover: live preview popout
// A "show desktop" strip sits at the end, like Windows.
// The bar gives it whatever height is left after every other entry; when there are more windows
// than fit, the tiles scroll instead of pushing the clock and status icons off screen.
Item {
    id: root

    property real tileSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small
    readonly property real stripHeight: desktopStrip.visible ? desktopStrip.height + Tokens.spacing.small : 0

    // The tile under a y coordinate in this item's space, for the bar's hover popout
    function tileAt(y: real): var {
        const p = mapToItem(tiles, tiles.width / 2, y);
        const tile = tiles.childAt(p.x, p.y);
        return tile?.modelData ? {
            tile: tile,
            item: tile.modelData
        } : null;
    }

    implicitWidth: root.tileSize
    implicitHeight: tiles.implicitHeight + stripHeight

    // A plain Column + Repeater (not a ListView): every tile always exists, so the list can't get
    // stuck showing only the tiles that fit while it was momentarily empty during a model update
    Flickable {
        id: scroller

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tileSize
        height: Math.max(0, Math.min(tiles.implicitHeight, root.height - root.stripHeight))
        contentHeight: tiles.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
            id: tiles

            width: root.tileSize
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: TaskbarState.items

                delegate: Item {
                    id: tile

                    required property var modelData
                    readonly property bool active: modelData.active ?? false
                    readonly property bool minimized: modelData.minimized ?? false
                    readonly property bool pinnedOnly: modelData.pinnedOnly ?? false
                    readonly property bool hovered: area.containsMouse

                    width: root.tileSize
                    height: root.tileSize

                    ChamferRect {
                        anchors.fill: parent
                        chamfer: Valorant.chamferSmall
                        topRight: 0
                        bottomLeft: 0
                        color: tile.active ? Qt.alpha(Colours.palette.m3primary, 0.22) : tile.hovered ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : tile.pinnedOnly ? "transparent" : Colours.tPalette.m3surfaceContainerHigh
                        borderColor: tile.active ? Colours.palette.m3primary : tile.minimized ? Qt.alpha(Colours.palette.m3outline, 0.6) : "transparent"
                        borderWidth: 1
                    }

                    // Running indicator on the left edge: long for the active window, short otherwise
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !tile.pinnedOnly
                        width: 3
                        height: tile.active ? parent.height * 0.6 : tile.minimized ? 4 : parent.height * 0.25
                        color: tile.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        opacity: tile.minimized ? 0.5 : 1

                        Behavior on height {
                            Anim {}
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.round(root.tileSize * 0.62)
                        asynchronous: true
                        source: tile.modelData.entry?.icon ? Quickshell.iconPath(tile.modelData.entry.icon, "image-missing") : Icons.getAppIcon(tile.modelData.appClass ?? "", "image-missing")
                        opacity: tile.minimized ? 0.4 : tile.pinnedOnly ? 0.75 : 1
                        scale: area.pressed ? 0.88 : 1

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    MouseArea {
                        id: area

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                TaskbarState.close(tile.modelData);
                            else if (event.button === Qt.RightButton)
                                TaskbarState.togglePin(tile.modelData);
                            else
                                TaskbarState.activate(tile.modelData);
                        }
                    }
                }
            }
        }
    }

    // Show desktop
    Item {
        id: desktopStrip

        anchors.top: scroller.bottom
        anchors.topMargin: Tokens.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.tileSize
        height: 10
        visible: TaskbarState.windows.length > 0

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: 2
            color: desktopArea.containsMouse ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        }

        MouseArea {
            id: desktopArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: TaskbarState.showDesktop()
        }
    }
}
