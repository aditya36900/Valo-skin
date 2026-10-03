import QtQuick
import qs.services

// Match-stats card backdrop: chamfered panel, corner brackets and a short accent along the top.
// Drop into a transparent container; renders beneath its siblings.
Item {
    id: root

    property color color
    property color accent: Colours.palette.m3primary

    anchors.fill: parent
    z: -1

    ChamferRect {
        anchors.fill: parent
        color: root.color
        borderColor: Colours.palette.m3outlineVariant
        borderWidth: Valorant.borderWidth
        chamfer: Valorant.chamfer
        topRight: 0
        bottomLeft: 0
    }

    CornerBrackets {
        inset: 3
        size: 7
        thickness: 1
        color: Qt.alpha(Colours.palette.m3onSurfaceVariant, 0.5)
    }

    AccentBar {
        edge: Qt.TopEdge
        thickness: 2
        leadFraction: 0.18
        color: root.accent
        width: parent.width * 0.5
        x: Valorant.chamfer
    }
}
