pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.valorant
import qs.services
import qs.modules.bar.components as BarComponents
import qs.modules.bar.popouts as BarPopouts

// The taskbar as its own always-visible dock on the right screen edge, with the full screen height
// for apps. It reserves its width so windows tile beside it, never under it. Hovering a tile
// shows the live preview to its left.
Scope {
    id: root

    required property ShellScreen screen
    // Hidden while a window is fullscreen, like the bar
    property bool hidden

    readonly property int dockWidth: win.contentItem.Tokens.sizes.bar.innerWidth + win.contentItem.Tokens.padding.large
    readonly property bool dockOn: Valorant.dockOn
    // Width the drawers frame must leave free on the right
    readonly property int reserved: dockOn && !hidden ? dockWidth : 0

    StyledWindow {
        id: exclusion

        screen: root.screen
        name: "dock-exclusion"
        visible: root.dockOn
        anchors.right: true
        exclusiveZone: root.dockWidth
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }

    StyledWindow {
        id: win

        // Tile the pointer is over, and whether the preview should stay up
        property var hit: null
        property bool previewWanted

        function updateHover(y: real): void {
            const h = taskbar.tileAt(win.contentItem.mapToItem(taskbar, 0, y).y);
            if (h) {
                hit = h;
                TaskbarState.hovered = h.item;
                previewWanted = true;
                closeTimer.stop();
            } else {
                closeTimer.restart();
            }
        }

        screen: root.screen
        name: "dock"
        visible: root.dockOn && !root.hidden
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        anchors.top: true
        anchors.bottom: true
        anchors.right: true
        implicitWidth: root.dockWidth

        Rectangle {
            anchors.fill: parent
            color: Colours.tPalette.m3surface
        }

        // Thin accent line down the inner edge, like the bar's HUD trim
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height * 0.4
            color: Qt.alpha(Colours.palette.m3primary, 0.35)
            visible: Valorant.accentBar
        }

        BarComponents.Taskbar {
            id: taskbar

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Tokens.padding.large
            anchors.bottomMargin: Tokens.padding.large
            tileSize: Tokens.sizes.bar.innerWidth
        }

        HoverHandler {
            id: dockHover

            onPointChanged: if (hovered)
                win.updateHover(point.position.y)
            onHoveredChanged: if (!hovered)
                closeTimer.restart()
        }

        Timer {
            id: closeTimer

            interval: 250
            onTriggered: if (!previewHover.hovered)
                win.previewWanted = false
        }

        PopupWindow {
            id: preview

            anchor.window: win
            anchor.rect.x: 0
            anchor.rect.y: win.hit?.tile ? win.hit.tile.mapToItem(win.contentItem, 0, 0).y : 0
            anchor.rect.width: 1
            anchor.rect.height: win.hit?.tile?.height ?? 1
            anchor.edges: Edges.Left
            anchor.gravity: Edges.Left
            anchor.margins.left: -preview.contentItem.Tokens.spacing.small
            visible: win.visible && win.previewWanted && !!win.hit
            color: "transparent"
            implicitWidth: card.implicitWidth + preview.contentItem.Tokens.padding.large * 2
            implicitHeight: card.implicitHeight + preview.contentItem.Tokens.padding.large * 2

            contentItem.Config.screen: root.screen.name
            contentItem.Tokens.screen: root.screen.name

            ChamferRect {
                anchors.fill: parent
                chamfer: Valorant.chamfer
                topRight: 0
                bottomLeft: 0
                color: Colours.tPalette.m3surface
                borderColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                borderWidth: 1
            }

            BarPopouts.TaskbarWindow {
                id: card

                anchors.centerIn: parent
            }

            HoverHandler {
                id: previewHover

                onHoveredChanged: hovered ? closeTimer.stop() : closeTimer.restart()
            }
        }
    }
}
