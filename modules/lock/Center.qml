import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Tokens.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.padding.large
        centerScale: root.centerScale
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter

        text: Time.format("dddd • d MMM").toUpperCase()
        color: Colours.palette.m3onSurface
        font: Tokens.font.title.builders.medium.weight(Font.DemiBold).build()
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.extraExtraLarge * root.centerScale
        Layout.bottomMargin: Tokens.spacing.extraLarge * root.centerScale
        centerWidth: root.centerWidth
    }

    Loader {
        Layout.alignment: Qt.AlignHCenter
        focus: true
        sourceComponent: Valorant.hudOn("spikeLock") ? spikeInput : stockInput
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }

    Component {
        id: spikeInput

        SpikePasswordInput {
            centerScale: Math.max(0.8, root.centerScale)
            centerWidth: root.centerWidth
            lock: root.lock
        }
    }

    Component {
        id: stockInput

        PasswordInput {
            centerScale: Math.max(0.8, root.centerScale)
            centerWidth: root.centerWidth
            lock: root.lock
        }
    }
}
