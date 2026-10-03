import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.utils

// Hover preview for a taskbar tile: live thumbnail, title and window controls.
ColumnLayout {
    id: root

    readonly property var item: TaskbarState.hovered

    spacing: Tokens.spacing.medium
    width: Math.max(300, Tokens.sizes.bar.windowPreviewSize)

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.padding.small
        spacing: Tokens.spacing.medium

        IconImage {
            implicitSize: titleCol.implicitHeight
            asynchronous: true
            source: root.item?.entry?.icon ? Quickshell.iconPath(root.item.entry.icon, "image-missing") : Icons.getAppIcon(root.item?.appClass ?? "", "image-missing")
        }

        ColumnLayout {
            id: titleCol

            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.item?.pinnedOnly ? (root.item?.entry?.name ?? root.item?.appClass ?? "") : (root.item?.title ?? "")
                elide: Text.ElideRight
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: root.item?.pinnedOnly ? qsTr("Pinned // click to launch") : root.item?.minimized ? qsTr("Minimized // click to restore") : root.item?.active ? qsTr("Active // click to minimize") : qsTr("Workspace %1").arg(root.item?.workspace ?? "")
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
                font: Tokens.font.label.small
            }
        }
    }

    ClippingWrapperRectangle {
        visible: !root.item?.pinnedOnly
        color: "transparent"
        radius: 0

        ScreencopyView {
            captureSource: root.item?.toplevel?.wayland ?? null // qmllint disable unresolved-type
            live: visible

            constraintSize.width: Tokens.sizes.bar.windowPreviewSize
            constraintSize.height: Tokens.sizes.bar.windowPreviewSize
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        HudIconButton {
            visible: !root.item?.pinnedOnly
            icon: root.item?.minimized ? "open_in_full" : "minimize"
            text: root.item?.minimized ? qsTr("Restore") : qsTr("Minimize")
            onClicked: root.item?.minimized ? Bench.restore(root.item.toplevel) : Bench.minimize(root.item?.address ?? "")
        }

        HudIconButton {
            icon: "add"
            text: qsTr("New")
            visible: !!root.item?.entry
            onClicked: TaskbarState.newInstance(root.item)
        }

        Item {
            Layout.fillWidth: true
        }

        HudIconButton {
            icon: root.item && TaskbarState.isPinned(root.item) ? "keep_off" : "keep"
            onClicked: TaskbarState.togglePin(root.item)
        }

        HudIconButton {
            visible: !root.item?.pinnedOnly
            icon: "close"
            onClicked: TaskbarState.close(root.item)
        }
    }
}
