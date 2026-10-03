pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.modules.nexus.common

// Valorant section of the Wallpaper & style page: agent select, palette, shape, effects and HUD toggles.
// Every control writes through Valorant.set(), so changes are saved to valorant.json.
ColumnLayout {
    id: root

    readonly property var hudRows: [
        {
            key: "roundTimerClock",
            text: qsTr("Round-timer clock"),
            subtext: qsTr("Bar clock drains every minute, red for the last 10 seconds")
        },
        {
            key: "abilitySlots",
            text: qsTr("Ability slots"),
            subtext: qsTr("Status icons in chamfered slots with charge pips")
        },
        {
            key: "rankWorkspaces",
            text: qsTr("Rank workspaces"),
            subtext: qsTr("Workspaces as diamond pips")
        },
        {
            key: "killBanners",
            text: qsTr("Kill banners"),
            subtext: qsTr("Notification popups styled as the kill feed")
        },
        {
            key: "chargeOsd",
            text: qsTr("Charge OSD"),
            subtext: qsTr("Volume and brightness as ability charge meters")
        },
        {
            key: "spikeLock",
            text: qsTr("Spike lock screen"),
            subtext: qsTr("Defuse the spike to unlock")
        },
        {
            key: "agentSelectLauncher",
            text: qsTr("Agent select"),
            subtext: qsTr("\">agent\" mode in the launcher")
        },
        {
            key: "matchStats",
            text: qsTr("Match stats"),
            subtext: qsTr("Dashboard cards as a match scoreboard")
        }
    ]

    Layout.fillWidth: true
    spacing: Tokens.spacing.large

    SectionHeader {
        text: qsTr("Agent")
    }

    Flow {
        id: agentGrid

        readonly property int columns: Math.max(4, Math.floor((width + spacing) / (72 + spacing)))
        readonly property real tileSize: (width - spacing * (columns - 1)) / columns

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            model: Valorant.agentIds

            Item {
                id: tile

                required property string modelData
                readonly property var info: Valorant.agents[modelData]
                readonly property bool locked: Valorant.agent === modelData

                implicitWidth: agentGrid.tileSize
                implicitHeight: agentGrid.tileSize

                ChamferRect {
                    anchors.fill: parent
                    color: Qt.alpha(tile.info.accent, tile.locked ? 0.3 : 0.1)
                    borderColor: tile.locked ? tile.info.accent : Qt.alpha(tile.info.accent, 0.4)
                    borderWidth: tile.locked ? 2 : 1
                    topRight: 0
                    bottomLeft: 0
                }

                StyledText {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Tokens.padding.small
                    text: tile.info.name.replace(/[^A-Za-z]/g, "").slice(0, 2)
                    color: tile.info.accent
                    font: Tokens.font.headline.medium
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Tokens.padding.small
                    width: parent.width - Tokens.padding.small * 2
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: tile.info.name
                    color: tile.locked ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.builders.small.scale(0.85).letterSpacing(0.3).build()
                }

                StateLayer {
                    onClicked: Valorant.setAgent(tile.modelData)
                }
            }
        }
    }

    SectionHeader {
        text: qsTr("Valorant style")
    }

    ToggleRow {
        first: true
        text: qsTr("Valorant styling")
        subtext: qsTr("Chamfered panels and every HUD component below")
        checked: Valorant.enabled
        onToggled: Valorant.set("enabled", checked)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        text: qsTr("Agent wallpapers")
        subtext: qsTr("Switch to the agent's wallpaper on lock-in")
        checked: Valorant.agentWallpapers
        onToggled: Valorant.set("agentWallpapers", checked)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        text: qsTr("Sync desktop colours")
        subtext: qsTr("Recolour Hyprland, terminals, GTK, Qt and the cursor with valo-sync")
        checked: Valorant.syncDotfiles
        onToggled: Valorant.set("syncDotfiles", checked)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        text: qsTr("Valorant palette")
        subtext: qsTr("Off uses the wallpaper colour scheme instead")
        checked: Valorant.overrideScheme
        onToggled: Valorant.set("overrideScheme", checked)
    }

    StepperRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - root.spacing

        label: qsTr("Chamfer size")
        subtext: qsTr("Corner bevel in pixels, 0 for square panels")
        value: Valorant.chamfer
        from: 0
        to: 32
        stepSize: 1
        onMoved: v => Valorant.set("shape.chamfer", v)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        text: qsTr("Corner brackets")
        checked: Valorant.cornerBrackets
        onToggled: Valorant.set("shape.cornerBrackets", checked)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        last: true
        text: qsTr("Accent bars")
        checked: Valorant.accentBar
        onToggled: Valorant.set("shape.accentBar", checked)
    }

    SectionHeader {
        text: qsTr("Effects")
    }

    StepperRow {
        first: true
        label: qsTr("Intensity")
        subtext: qsTr("Spike pulse, shake, banner flash and glitch strength")
        value: Valorant.fxIntensity
        from: 0
        to: 2
        stepSize: 0.25
        onMoved: v => Valorant.set("fx.intensity", v)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        text: qsTr("Glitch on agent switch")
        checked: Valorant.glitch
        onToggled: Valorant.set("fx.glitch", checked)
    }

    ToggleRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

        last: true
        text: qsTr("Scanlines")
        subtext: qsTr("Subtle scanline overlay on panels")
        checked: Valorant.scanlines
        onToggled: Valorant.set("fx.scanlines", checked)
    }

    SectionHeader {
        text: qsTr("Sound")
    }

    ToggleRow {
        first: true
        text: qsTr("UI sounds")
        subtext: qsTr("Lock-in, spike plant and defuse, kill-banner ping")
        checked: Valorant.cfg.sounds?.enabled ?? true
        onToggled: {
            Valorant.set("sounds.enabled", checked);
            if (checked)
                Valorant.play("tick");
        }
    }

    StepperRow {
        Layout.topMargin: Tokens.spacing.extraSmall / 2 - root.spacing

        last: true
        label: qsTr("Volume")
        value: Math.round(Valorant.soundVolume * 100)
        from: 0
        to: 100
        stepSize: 10
        onMoved: v => {
            Valorant.set("sounds.volume", v / 100);
            Valorant.play("tick");
        }
    }

    SectionHeader {
        text: qsTr("HUD")
    }

    Repeater {
        model: root.hudRows

        ToggleRow {
            required property var modelData
            required property int index

            Layout.topMargin: index === 0 ? 0 : Tokens.spacing.extraSmall / 2 - root.spacing
            first: index === 0
            last: index === root.hudRows.length - 1
            text: modelData.text
            subtext: modelData.subtext
            checked: Valorant.hud[modelData.key] ?? true
            onToggled: Valorant.set(`hud.${modelData.key}`, checked)
        }
    }
}
