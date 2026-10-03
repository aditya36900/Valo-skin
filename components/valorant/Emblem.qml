import QtQuick
import QtQuick.Shapes
import qs.services

// The Valo-skin crosshair emblem (assets/logo.svg) drawn as vectors, so it can take the agent
// accent. Used instead of the distro logo in the bar, lock screen and dashboard.
Item {
    id: root

    property color frameColor: Colours.palette.m3onSurface
    property color crossColor: Colours.palette.m3primary
    property real size: 24

    implicitWidth: size
    implicitHeight: size

    Item {
        // logo.svg coordinates (y shifted by -8): 128 x 74.4
        width: 128
        height: 74.4
        anchors.centerIn: parent
        scale: root.size / 128

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.frameColor
                strokeWidth: -1
                startX: 22
                startY: 0

                PathPolyline {
                    path: [Qt.point(22, 0), Qt.point(8, 14), Qt.point(8, 60.4), Qt.point(22, 74.4), Qt.point(30, 74.4), Qt.point(30, 68.4), Qt.point(24.5, 68.4), Qt.point(14, 57.9), Qt.point(14, 16.5), Qt.point(24.5, 6), Qt.point(30, 6), Qt.point(30, 0), Qt.point(22, 0)]
                }
            }

            ShapePath {
                fillColor: root.frameColor
                strokeWidth: -1
                startX: 106
                startY: 0

                PathPolyline {
                    path: [Qt.point(106, 0), Qt.point(120, 14), Qt.point(120, 60.4), Qt.point(106, 74.4), Qt.point(98, 74.4), Qt.point(98, 68.4), Qt.point(103.5, 68.4), Qt.point(114, 57.9), Qt.point(114, 16.5), Qt.point(103.5, 6), Qt.point(98, 6), Qt.point(98, 0), Qt.point(106, 0)]
                }
            }
        }

        Repeater {
            model: [[34, 35, 18, 4.4], [76, 35, 18, 4.4], [61.8, 7, 4.4, 18], [61.8, 49.4, 4.4, 18], [61.8, 35, 4.4, 4.4]]

            Rectangle {
                required property var modelData

                x: modelData[0]
                y: modelData[1]
                width: modelData[2]
                height: modelData[3]
                color: root.crossColor
                antialiasing: true
            }
        }
    }
}
