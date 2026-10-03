import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services

Item {
    id: root

    required property Props props
    required property ScreenState screenState

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Valorant.hudOn("matchHistory") ? "transparent" : Colours.tPalette.m3surfaceContainerLow

            Loader {
                anchors.fill: parent
                z: -1
                active: Valorant.hudOn("matchHistory")

                sourceComponent: HudCard {
                    color: Colours.tPalette.m3surfaceContainerLow
                }
            }

            NotifDock {
                objectName: "sidebarNotifications"

                props: root.props
                screenState: root.screenState
            }
        }

        StyledRect {
            Layout.topMargin: Tokens.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
