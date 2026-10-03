import QtQuick
import qs.components
import qs.services

// Thin accent strip along one edge of the parent, with a short bright lead segment
Item {
    id: root

    property int edge: Qt.LeftEdge
    property color color: Colours.palette.m3primary
    property real thickness: 3
    property real leadFraction: 0.35
    readonly property bool vertical: edge === Qt.LeftEdge || edge === Qt.RightEdge

    x: edge === Qt.RightEdge ? parent.width - thickness : 0
    y: edge === Qt.BottomEdge ? parent.height - thickness : 0
    width: vertical ? thickness : parent.width
    height: vertical ? parent.height : thickness
    visible: Valorant.enabled && Valorant.accentBar

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(root.color, 0.35)
    }

    StyledRect {
        width: root.vertical ? parent.width : parent.width * root.leadFraction
        height: root.vertical ? parent.height * root.leadFraction : parent.height
        color: root.color
    }
}
