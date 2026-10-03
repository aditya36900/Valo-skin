pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

// Ability-charge style pips: `count` small slanted cells, filled up to `value` (0-1)
Grid {
    id: root

    property int count: 4
    property real value: 0
    property bool vertical: false
    property real pipLength: 6
    property real pipThickness: 3
    property color fillColor: Colours.palette.m3onSurface
    property color emptyColor: Qt.alpha(Colours.palette.m3onSurface, 0.2)
    readonly property int filled: Math.round(Math.max(0, Math.min(1, value)) * count)

    rows: vertical ? count : 1
    columns: vertical ? 1 : count
    spacing: 2

    Repeater {
        model: root.count

        ChamferRect {
            required property int index
            // Vertical pips fill bottom-up like a charge meter
            readonly property bool on: (root.vertical ? root.count - 1 - index : index) < root.filled

            implicitWidth: root.pipLength
            implicitHeight: root.pipThickness
            chamfer: 0
            topRight: root.pipThickness * 0.8
            bottomLeft: root.pipThickness * 0.8
            color: on ? root.fillColor : root.emptyColor
        }
    }
}
