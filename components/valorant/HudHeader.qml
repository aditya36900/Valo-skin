import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Popout title: accent strip, uppercase title and a dim subtitle line.
Row {
    id: root

    property string title
    property string subtitle
    property color accent: Colours.palette.m3primary

    spacing: Tokens.spacing.small

    ChamferRect {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 5
        implicitHeight: titleCol.implicitHeight
        chamfer: 0
        bottomRight: 2.5
        color: root.accent
    }

    Column {
        id: titleCol

        StyledText {
            text: root.title
            font: Tokens.font.title.medium
        }

        StyledText {
            visible: text.length > 0
            text: root.subtitle
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }
}
