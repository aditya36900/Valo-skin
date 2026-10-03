import QtQuick
import qs.components
import qs.services

// Valorant kill-feed banner backdrop: slanted chamfered card, accent stripe and an arrival flash.
// Place as the first child of a container so content renders above it.
Item {
    id: root

    property color color: Colours.tPalette.m3surfaceContainer
    property color accent: Colours.palette.m3primary
    property bool flashOnShow: Valorant.fxIntensity > 0

    anchors.fill: parent

    ChamferRect {
        id: card

        anchors.fill: parent
        color: root.color
        borderColor: Qt.alpha(root.accent, 0.35)
        borderWidth: 1
        chamfer: Valorant.chamfer
        topLeft: 0
        bottomRight: 0
    }

    // Accent stripe hugging the left edge, cut to follow the bottom-left bevel
    ChamferRect {
        x: 0
        y: 0
        width: 4
        height: parent.height - Valorant.chamfer
        chamfer: 0
        bottomRight: 4
        color: root.accent
        visible: Valorant.accentBar
    }

    ChamferRect {
        id: flash

        anchors.fill: parent
        chamfer: Valorant.chamfer
        topLeft: 0
        bottomRight: 0
        color: root.accent
        opacity: 0
    }

    SequentialAnimation {
        running: root.flashOnShow
        alwaysRunToEnd: true

        NumberAnimation {
            target: flash
            property: "opacity"
            to: 0.45 * Math.min(1, Valorant.fxIntensity)
            duration: 60
        }
        NumberAnimation {
            target: flash
            property: "opacity"
            to: 0
            duration: 420
            easing.type: Easing.OutCubic
        }
    }
}
