pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.valorant
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property string connectingToSsid: ""
    property string view: "wireless" // "wireless" or "ethernet"
    property var passwordNetwork: null
    property bool showPasswordDialog: false
    property string filter: "all" // all | saved | open | secure

    readonly property real rowHeight: Math.round(Tokens.font.body.medium.pointSize * 2.9)
    // Every SSID in range (Nmcli already merges access points that share a name), strongest first
    readonly property var wifiNetworks: [...Nmcli.networks].filter(n => n.ssid).sort((a, b) => {
        if (a.active !== b.active)
            return b.active - a.active;
        return b.strength - a.strength;
    })
    readonly property var filteredNetworks: wifiNetworks.filter(n => matches(n, filter))

    function matches(n: var, f: string): bool {
        if (f === "saved")
            return Nmcli.hasSavedProfile(n.ssid);
        if (f === "open")
            return !n.isSecure;
        if (f === "secure")
            return n.isSecure;
        return true;
    }

    function countFor(f: string): int {
        return wifiNetworks.filter(n => matches(n, f)).length;
    }

    function bandLabel(freq: int): string {
        if (freq >= 5925)
            return "6G";
        if (freq >= 4900)
            return "5G";
        if (freq > 0)
            return "2.4G";
        return "";
    }

    function toggleNetwork(network: var): void {
        if (network.active) {
            Nmcli.disconnectFromNetwork();
            return;
        }
        connectingToSsid = network.ssid;
        NetworkConnection.handleConnect(network, null, n => {
            // Password is required - show password dialog
            passwordNetwork = n;
            showPasswordDialog = true;
            popouts.currentName = "wirelesspassword";
        });
    }

    spacing: Tokens.spacing.small
    width: Math.max(Tokens.sizes.bar.networkWidth, 360)

    // Wireless section: Valorant "comms" panel
    RowLayout {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        ChamferRect {
            implicitWidth: 5
            implicitHeight: commsTitle.implicitHeight + Tokens.font.label.small.pointSize
            chamfer: 0
            bottomRight: 2
            color: Colours.palette.m3primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: commsTitle

                text: qsTr("Comms")
                font: Tokens.font.title.medium
            }

            StyledText {
                text: Nmcli.wifiEnabled ? qsTr("Wireless // %1 in range").arg(root.wifiNetworks.length) : qsTr("Wireless // offline")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }

        StyledSwitch {
            checked: Nmcli.wifiEnabled
            onToggled: Nmcli.enableWifi(checked)
        }
    }

    // Current connection
    Item {
        visible: root.view === "wireless" && !!Nmcli.active
        Layout.preferredHeight: visible ? activeRow.implicitHeight + Tokens.padding.medium * 2 : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall

        HudCard {
            color: Qt.alpha(Colours.palette.m3primary, 0.12)
        }

        RowLayout {
            id: activeRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            SignalPips {
                strength: Nmcli.active?.strength ?? 0
                active: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: qsTr("Connected")
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Nmcli.active?.ssid ?? ""
                    elide: Text.ElideRight
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: [root.bandLabel(Nmcli.active?.frequency ?? 0), Nmcli.active?.security || qsTr("Open"), `${Nmcli.active?.strength ?? 0}%`].filter(s => s).join("  ·  ")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            HudButton {
                icon: "link_off"
                onClicked: Nmcli.disconnectFromNetwork()
            }
        }
    }

    // Filters
    RowLayout {
        visible: root.view === "wireless" && Nmcli.wifiEnabled
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: [
                {
                    id: "all",
                    label: qsTr("All")
                },
                {
                    id: "saved",
                    label: qsTr("Saved")
                },
                {
                    id: "open",
                    label: qsTr("Open")
                },
                {
                    id: "secure",
                    label: qsTr("Locked")
                }
            ]

            Item {
                id: chip

                required property var modelData
                readonly property bool selected: root.filter === modelData.id

                Layout.fillWidth: true
                Layout.preferredWidth: chipLabel.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: chipLabel.implicitHeight + Tokens.padding.small * 2

                ChamferRect {
                    anchors.fill: parent
                    chamfer: Valorant.chamferSmall
                    topRight: 0
                    bottomLeft: 0
                    color: chip.selected ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                }

                StyledText {
                    id: chipLabel

                    anchors.centerIn: parent
                    text: `${chip.modelData.label} ${root.countFor(chip.modelData.id)}`
                    color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                StateLayer {
                    radius: 0
                    color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    onClicked: root.filter = chip.modelData.id
                }
            }
        }
    }

    // Every network in range, scrollable
    StyledListView {
        id: networkList

        visible: root.view === "wireless" && Nmcli.wifiEnabled
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        Layout.preferredHeight: visible ? Math.min(contentHeight, root.rowHeight * 7.5) : 0
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: root.filteredNetworks
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: networkList
        }

        delegate: Item {
            id: networkItem

            required property Nmcli.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly property bool saved: Nmcli.hasSavedProfile(modelData.ssid)

            width: networkList.width - (networkList.contentHeight > networkList.height ? Tokens.padding.small : 0)
            implicitHeight: root.rowHeight

            ChamferRect {
                anchors.fill: parent
                chamfer: 0
                topLeft: Valorant.chamferSmall
                bottomRight: Valorant.chamferSmall
                color: networkItem.modelData.active ? Qt.alpha(Colours.palette.m3primary, 0.14) : rowHover.containsMouse ? Colours.layer(Colours.palette.m3surfaceContainerHigh, 2) : "transparent"
            }

            StateLayer {
                id: rowHover

                radius: 0
                disabled: networkItem.isConnecting || !Nmcli.wifiEnabled
                onClicked: root.toggleNetwork(networkItem.modelData)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.extraSmall
                spacing: Tokens.spacing.small

                SignalPips {
                    strength: networkItem.modelData.strength
                    active: networkItem.modelData.active
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.spacing.extraSmall
                    text: networkItem.modelData.ssid
                    elide: Text.ElideRight
                    font: Tokens.font.body.builders.medium.weight(networkItem.modelData.active ? Font.Medium : Font.Normal).build()
                    color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                }

                MaterialIcon {
                    visible: networkItem.saved
                    text: "bookmark"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                MaterialIcon {
                    visible: networkItem.modelData.isSecure
                    text: "lock"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                Tag {
                    text: root.bandLabel(networkItem.modelData.frequency)
                }

                Item {
                    implicitWidth: implicitHeight
                    implicitHeight: linkIcon.implicitHeight

                    CircularIndicator {
                        anchors.fill: parent
                        running: networkItem.isConnecting
                    }

                    MaterialIcon {
                        id: linkIcon

                        anchors.centerIn: parent
                        text: networkItem.modelData.active ? "link_off" : "link"
                        color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        opacity: networkItem.isConnecting ? 0 : 1
                    }
                }
            }
        }
    }

    StyledText {
        visible: root.view === "wireless" && Nmcli.wifiEnabled && root.filteredNetworks.length === 0
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        text: Nmcli.scanning ? qsTr("Scanning…") : qsTr("No networks match")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    // Rescan + full settings
    RowLayout {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.fillWidth: true
        Layout.rightMargin: Tokens.padding.extraSmall
        spacing: Tokens.spacing.small

        Item {
            Layout.fillWidth: true
            implicitHeight: rescanBtn.implicitHeight + Tokens.padding.small * 2

            ChamferRect {
                anchors.fill: parent
                chamfer: Valorant.chamferSmall
                topRight: 0
                bottomLeft: 0
                color: Colours.palette.m3primaryContainer
            }

            StateLayer {
                radius: 0
                color: Colours.palette.m3onPrimaryContainer
                disabled: Nmcli.scanning || !Nmcli.wifiEnabled
                onClicked: Nmcli.rescanWifi()
            }

            RowLayout {
                id: rescanBtn

                anchors.centerIn: parent
                spacing: Tokens.spacing.small
                opacity: Nmcli.scanning ? 0 : 1

                MaterialIcon {
                    id: scanIcon

                    text: "wifi_find"
                    color: Colours.palette.m3onPrimaryContainer
                }

                StyledText {
                    text: qsTr("Rescan")
                    color: Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.label.medium
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            CircularIndicator {
                anchors.centerIn: parent
                strokeWidth: Tokens.padding.extraSmall / 2
                bgColour: "transparent"
                implicitSize: parent.implicitHeight - Tokens.padding.medium
                running: Nmcli.scanning
            }
        }

        HudButton {
            icon: "settings"
            onClicked: root.popouts.detachRequested("network")
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.padding.medium : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("Ethernet")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Tokens.spacing.small : 0
        Layout.rightMargin: Tokens.padding.extraSmall
        text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    Repeater {
        visible: root.view === "ethernet"
        model: ScriptModel {
            values: [...Nmcli.ethernetDevices].sort((a, b) => {
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return (a.iface || "").localeCompare(b.iface || "");
            }).slice(0, 8)
        }

        RowLayout {
            id: ethernetItem

            required property var modelData
            readonly property bool loading: false

            visible: root.view === "ethernet"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: Tokens.padding.extraSmall
            spacing: Tokens.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: "cable"
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.leftMargin: Tokens.spacing.extraSmall
                Layout.rightMargin: Tokens.spacing.extraSmall
                Layout.fillWidth: true
                text: ethernetItem.modelData.iface || qsTr("Unknown")
                elide: Text.ElideRight
                font: Tokens.font.body.builders.medium.weight(ethernetItem.modelData.connected ? Font.Medium : Font.Normal).build()
                color: ethernetItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Tokens.padding.extraSmall

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: ethernetItem.loading
                }

                StateLayer {
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: ethernetItem.loading

                    onClicked: {
                        if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.iface || "", () => {});
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethernetItem.modelData.connected ? "link_off" : "link"
                    color: ethernetItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: ethernetItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.popouts.currentName === "wirelesspassword") {
                        root.popouts.currentName = "network";
                    }
                }
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }

        target: Nmcli
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.popouts.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.popouts
    }

    // Four rising bars, filled by signal strength
    component SignalPips: Row {
        id: pips

        property int strength
        property bool active

        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        Repeater {
            model: 4

            ChamferRect {
                required property int index
                readonly property bool on: pips.strength > index * 25 + 5

                anchors.bottom: parent.bottom
                implicitWidth: 4
                implicitHeight: 6 + index * 3
                chamfer: 0
                topRight: 1.5
                color: on ? (pips.active ? Colours.palette.m3primary : Colours.palette.m3onSurface) : Qt.alpha(Colours.palette.m3onSurface, 0.2)
            }
        }
    }

    component Tag: Item {
        property alias text: tagLabel.text

        visible: text.length > 0
        implicitWidth: tagLabel.implicitWidth + Tokens.padding.small * 2
        implicitHeight: tagLabel.implicitHeight + 2

        ChamferRect {
            anchors.fill: parent
            chamfer: 0
            topRight: 3
            bottomLeft: 3
            borderColor: Colours.palette.m3outlineVariant
            borderWidth: 1
        }

        StyledText {
            id: tagLabel

            anchors.centerIn: parent
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }

    component HudButton: Item {
        id: hudBtn

        property alias icon: hudBtnIcon.text

        signal clicked

        implicitWidth: implicitHeight
        implicitHeight: hudBtnIcon.implicitHeight + Tokens.padding.small * 2

        ChamferRect {
            anchors.fill: parent
            chamfer: Valorant.chamferSmall
            topRight: 0
            bottomLeft: 0
            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            borderColor: Colours.palette.m3outlineVariant
            borderWidth: 1
        }

        StateLayer {
            radius: 0
            onClicked: hudBtn.clicked()
        }

        MaterialIcon {
            id: hudBtnIcon

            anchors.centerIn: parent
            color: Colours.palette.m3onSurface
        }
    }
}
