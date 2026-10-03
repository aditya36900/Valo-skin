import QtQuick
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

// Current tiling layout; click (or scroll) to switch. SUPER+ALT+T does the same.
Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small * 2
    implicitHeight: icon.implicitHeight + Tokens.padding.small * 2

    ChamferRect {
        anchors.fill: parent
        chamfer: Valorant.chamferSmall
        topRight: 0
        bottomLeft: 0
        color: area.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 2) : "transparent"
        borderColor: Colours.palette.m3outlineVariant
        borderWidth: 1
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        animate: true
        text: Layouts.icon
        color: Colours.palette.m3primary
        fontStyle: Tokens.font.icon.small
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Layouts.next()
        onWheel: Layouts.next()
    }
}
