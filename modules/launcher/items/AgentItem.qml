import QtQuick
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.modules.launcher.services

// Agent-select row: chamfered portrait tile in the agent's colour, name, role and lock-in tag
Item {
    id: root

    required property Agents.Agent modelData
    required property var list
    readonly property bool locked: root.modelData?.agentId === Valorant.agent

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Item {
            id: portrait

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: parent.height * 0.9
            implicitHeight: parent.height * 0.9

            ChamferRect {
                anchors.fill: parent
                color: Qt.alpha(root.modelData?.accent ?? "transparent", 0.18)
                borderColor: root.modelData?.accent ?? "transparent"
                borderWidth: root.locked ? 2 : 1
                topRight: 0
                bottomLeft: 0
            }

            StyledText {
                anchors.centerIn: parent
                text: (root.modelData?.name ?? "").replace(/[^A-Za-z]/g, "").slice(0, 2)
                color: root.modelData?.accent ?? Colours.palette.m3onSurface
                font: Tokens.font.headline.small
            }
        }

        Column {
            anchors.left: portrait.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - portrait.width - anchors.leftMargin - tag.width - Tokens.spacing.medium
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font: Tokens.font.title.medium
            }

            Row {
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.modelData?.roleIcon ?? ""
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.modelData?.role ?? ""
                    font: Tokens.font.label.medium
                    color: Colours.palette.m3outline
                }
            }
        }

        Item {
            id: tag

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: tagText.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: tagText.implicitHeight + Tokens.padding.extraSmall * 2
            visible: root.locked

            ChamferRect {
                anchors.fill: parent
                color: root.modelData?.accent ?? "transparent"
                topLeft: 0
                bottomRight: 0
            }

            StyledText {
                id: tagText

                anchors.centerIn: parent
                text: qsTr("Locked in")
                color: Valorant.onColour(root.modelData?.accent ?? "black")
                font: Tokens.font.label.medium
            }
        }
    }
}
