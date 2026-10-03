pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services

Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    property real star1Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star2Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star3Opacity: skipIntroAnimation ? 1.0 : 0.0

    property real star1Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star2Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star3Scale: skipIntroAnimation ? 1.0 : 0.0

    readonly property alias topShape: topShape
    readonly property alias bottomShape: bottomShape
    readonly property alias star1: star1
    readonly property alias star2: star2
    readonly property alias star3: star3

    signal animationCompleted

    implicitWidth: 128
    implicitHeight: 90.38

    Item {
        id: logo

        readonly property real designWidth: 128
        readonly property real designHeight: 90.38

        property color topColour: Colours.palette.m3primary
        property color bottomColour: Colours.palette.m3onSurface

        implicitWidth: designWidth
        implicitHeight: designHeight

        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1.0 : 0.0
        opacity: root.skipIntroAnimation ? 1.0 : 0.0
        rotation: 0.0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        Component.onCompleted: {
            root.star1.opacity = Qt.binding(() => root.star1Opacity);
            root.star1.scale = Qt.binding(() => root.star1Scale);
            root.star2.opacity = Qt.binding(() => root.star2Opacity);
            root.star2.scale = Qt.binding(() => root.star2Scale);
            root.star3.opacity = Qt.binding(() => root.star3Opacity);
            root.star3.scale = Qt.binding(() => root.star3Scale);
        }

        Behavior on topColour {
            CAnim {}
        }

        Behavior on bottomColour {
            CAnim {}
        }

        Shape {
            id: topShape

            anchors.centerIn: parent
            width: logo.designWidth
            height: logo.designHeight
            scale: Math.min(logo.width / width, logo.height / height)
            transformOrigin: Item.Center
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M34,43 L52,43 L52,47.4 L34,47.4 Z M76,43 L94,43 L94,47.4 L76,47.4 Z M61.8,15 L66.2,15 L66.2,33 L61.8,33 Z M61.8,57.4 L66.2,57.4 L66.2,75.4 L61.8,75.4 Z"
                }
            }
        }

        Shape {
            id: bottomShape

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.bottomColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M22,8 L8,22 L8,68.4 L22,82.4 L30,82.4 L30,76.4 L24.5,76.4 L14,65.9 L14,24.5 L24.5,14 L30,14 L30,8 Z M106,8 L120,22 L120,68.4 L106,82.4 L98,82.4 L98,76.4 L103.5,76.4 L114,65.9 L114,24.5 L103.5,14 L98,14 L98,8 Z"
                }
            }
        }

        Shape {
            id: star1

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M64,40.99 L68.2,45.19 L64,49.39 L59.8,45.19 Z"
                }
            }
        }

        Shape {
            id: star2

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M64,2.4 L66.6,5 L64,7.6 L61.4,5 Z"
                }
            }
        }

        Shape {
            id: star3

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.0

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M64,82.8 L66.6,85.4 L64,88 L61.4,85.4 Z"
                }
            }
        }
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 0
                    to: 750
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 750
                    to: 710
                    duration: 300
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 710
                    to: 725
                    duration: 350
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "rotation"
                    from: 725
                    to: 720
                    duration: 250
                    easing.type: Easing.OutQuad
                }

                ScriptAction {
                    script: logo.rotation = 0
                }
            }

            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.0
                    to: 1.08
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.08
                    to: 0.96
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.96
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            NumberAnimation {
                target: logo
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 600
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root
                property: "blurAmount"
                from: 1.0
                to: 0.0
                duration: 900
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1100
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star1Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star1Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1250
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star2Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star2Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 1400
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: root
                        property: "star3Opacity"
                        from: 0.0
                        to: 1.0
                        duration: 700
                        easing.type: Easing.InOutQuad
                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 0.0
                            to: 1.08
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                        NumberAnimation {
                            target: root
                            property: "star3Scale"
                            from: 1.08
                            to: 1.0
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite

        PauseAnimation {
            duration: 2500
        }

        ParallelAnimation {
            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y
                    to: root.star1.y - 5
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "y"
                    from: root.star1.y - 5
                    to: root.star1.y
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y
                    to: root.star2.y + 5
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "y"
                    from: root.star2.y + 5
                    to: root.star2.y
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y
                    to: root.star3.y - 5
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "y"
                    from: root.star3.y - 5
                    to: root.star3.y
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star1
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2500
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.0
                    to: 1.12
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star2
                    property: "scale"
                    from: 1.12
                    to: 1.0
                    duration: 3000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation {
                loops: Animation.Infinite

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.0
                    to: 1.08
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: root.star3
                    property: "scale"
                    from: 1.08
                    to: 1.0
                    duration: 2800
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
