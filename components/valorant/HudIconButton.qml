import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Chamfered HUD button with an icon and optional label. `primary` fills it with the accent.
Item {
    id: root

    property string icon
    property string text
    property bool primary

    signal clicked

    implicitWidth: text ? row.implicitWidth + Tokens.padding.large * 2 : implicitHeight
    implicitHeight: iconLabel.implicitHeight + Tokens.padding.small * 2
    opacity: enabled ? 1 : 0.45

    ChamferRect {
        anchors.fill: parent
        chamfer: Valorant.chamferSmall
        topRight: 0
        bottomLeft: 0
        color: root.primary ? (area.containsMouse ? Qt.lighter(Colours.palette.m3primary, 1.1) : Colours.palette.m3primary) : area.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHighest, 2) : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
        borderColor: root.primary ? "transparent" : Colours.palette.m3outlineVariant
        borderWidth: 1
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: iconLabel

            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text.length > 0
            text: root.text
            color: root.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            font: Tokens.font.label.medium
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
