import QtQuick
import QtQuick.Shapes
import qs.services

// Valo-skin crosshair emblem (original artwork, see scripts/gen-valorant-art.py)
Item {
    id: root

    readonly property real designWidth: 128
    readonly property real designHeight: 90.38

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.bottomColour
            strokeColor: "transparent"

            PathSvg {
                path: "M22,8 L8,22 L8,68.4 L22,82.4 L30,82.4 L30,76.4 L24.5,76.4 L14,65.9 L14,24.5 L24.5,14 L30,14 L30,8 Z M106,8 L120,22 L120,68.4 L106,82.4 L98,82.4 L98,76.4 L103.5,76.4 L114,65.9 L114,24.5 L103.5,14 L98,14 L98,8 Z"
            }
        }

        ShapePath {
            fillColor: root.topColour
            strokeColor: "transparent"

            PathSvg {
                path: "M34,43 L52,43 L52,47.4 L34,47.4 Z M76,43 L94,43 L94,47.4 L76,47.4 Z M61.8,15 L66.2,15 L66.2,33 L61.8,33 Z M61.8,57.4 L66.2,57.4 L66.2,75.4 L61.8,75.4 Z M61.8,43 L66.2,43 L66.2,47.4 L61.8,47.4 Z"
            }
        }
    }
}
