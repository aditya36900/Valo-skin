import QtQuick
import qs.components
import qs.services

// Four L-shaped HUD brackets hugging the parent's corners
Item {
    id: root

    property color color: Colours.palette.m3outline
    property real size: 8
    property real thickness: 1.5
    property real inset: 0

    anchors.fill: parent
    anchors.margins: inset
    visible: Valorant.enabled && Valorant.cornerBrackets

    Repeater {
        model: 4

        Item {
            id: corner

            required property int index
            readonly property bool isRight: index === 1 || index === 2
            readonly property bool isBottom: index >= 2

            x: isRight ? root.width - root.size : 0
            y: isBottom ? root.height - root.size : 0
            width: root.size
            height: root.size

            StyledRect {
                y: corner.isBottom ? parent.height - height : 0
                width: parent.width
                height: root.thickness
                color: root.color
            }

            StyledRect {
                x: corner.isRight ? parent.width - width : 0
                width: root.thickness
                height: parent.height
                color: root.color
            }
        }
    }
}
