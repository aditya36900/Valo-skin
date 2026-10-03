import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

// One clipboard entry in the launcher's ">clip" mode: text preview or image thumbnail, with pin
// and delete buttons. Enter / click copies it back to the clipboard.
Item {
    id: root

    required property var modelData
    required property var list

    readonly property bool isImage: modelData?.image ?? false
    readonly property string thumb: modelData?.kind === "pin" ? (modelData?.path ?? "") : Stash.thumbnail(modelData?.id ?? "")

    implicitHeight: isImage ? Tokens.sizes.launcher.itemHeight * 1.6 : Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    Component.onCompleted: if (isImage && modelData?.kind === "pin")
        image.source = `file://${thumb}`

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.small
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.pinned ? "keep" : root.isImage ? "image" : "content_paste"
            color: root.modelData?.pinned ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.1).build()
        }

        Image {
            id: image

            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            visible: root.isImage
            height: parent.height
            width: Math.min(parent.width * 0.5, height * 2)
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            asynchronous: true
            cache: false
            sourceSize.height: height * 2
            source: ""
        }

        StyledText {
            anchors.left: root.isImage ? image.right : icon.right
            anchors.right: buttons.left
            anchors.leftMargin: Tokens.spacing.medium
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            text: root.isImage ? (root.modelData?.preview ?? "").replace(/^\[\[ binary data /, "").replace(/ \]\]$/, "") : (root.modelData?.preview ?? "").replace(/\s+/g, " ")
            font: root.isImage ? Tokens.font.body.small : Tokens.font.body.medium
            color: root.isImage ? Colours.palette.m3outline : Colours.palette.m3onSurface
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAnywhere
        }

        Row {
            id: buttons

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.extraSmall

            ItemButton {
                visible: !root.modelData?.pinned
                icon: "keep"
                onClicked: Stash.pin(root.modelData)
            }

            ItemButton {
                icon: "delete"
                onClicked: Stash.remove(root.modelData)
            }
        }
    }

    // Decode image entries to a cached PNG once, then show it
    Process {
        running: root.isImage && root.modelData?.kind === "entry"
        command: ["sh", "-c", 'mkdir -p "$(dirname "$2")"; [ -s "$2" ] || cliphist decode "$1" > "$2"', "valo-stash", root.modelData?.id ?? "", root.thumb]
        onExited: image.source = `file://${root.thumb}`
    }

    component ItemButton: Item {
        id: btn

        property alias icon: btnIcon.text

        signal clicked

        implicitWidth: implicitHeight
        implicitHeight: btnIcon.implicitHeight + Tokens.padding.small * 2

        ChamferRect {
            anchors.fill: parent
            chamfer: Valorant.chamferSmall
            topRight: 0
            bottomLeft: 0
            color: btnArea.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 2) : "transparent"
        }

        MaterialIcon {
            id: btnIcon

            anchors.centerIn: parent
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }

        MouseArea {
            id: btnArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
