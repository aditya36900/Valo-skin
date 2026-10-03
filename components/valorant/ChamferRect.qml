import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

// Rectangle with 45-degree cut corners, the core Valorant HUD shape.
// A square with every corner cut to half its size is a diamond.
Shape {
    id: root

    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real chamfer: Valorant.chamferSmall
    property real topLeft: chamfer
    property real topRight: chamfer
    property real bottomRight: chamfer
    property real bottomLeft: chamfer

    readonly property real maxCut: Math.max(0, Math.min(width, height) / 2)
    readonly property real inset: borderWidth / 2
    readonly property real tl: Math.min(maxCut, Math.max(0, topLeft))
    readonly property real tr: Math.min(maxCut, Math.max(0, topRight))
    readonly property real br: Math.min(maxCut, Math.max(0, bottomRight))
    readonly property real bl: Math.min(maxCut, Math.max(0, bottomLeft))
    readonly property real x0: inset
    readonly property real y0: inset
    readonly property real x1: width - inset
    readonly property real y1: height - inset

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        strokeWidth: root.borderWidth
        joinStyle: ShapePath.MiterJoin
        startX: root.x0 + root.tl
        startY: root.y0

        PathLine {
            x: root.x1 - root.tr
            y: root.y0
        }
        PathLine {
            x: root.x1
            y: root.y0 + root.tr
        }
        PathLine {
            x: root.x1
            y: root.y1 - root.br
        }
        PathLine {
            x: root.x1 - root.br
            y: root.y1
        }
        PathLine {
            x: root.x0 + root.bl
            y: root.y1
        }
        PathLine {
            x: root.x0
            y: root.y1 - root.bl
        }
        PathLine {
            x: root.x0
            y: root.y0 + root.tl
        }
        PathLine {
            x: root.x0 + root.tl
            y: root.y0
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on borderColor {
        CAnim {}
    }
}
