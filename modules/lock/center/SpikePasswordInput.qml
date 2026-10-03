pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.valorant
import qs.services
import qs.modules.lock

// Valorant spike-plant password input. Typing fills the defuse bar, Enter "defuses" (authenticates).
// Key handling and focus behaviour mirror PasswordInput so PAM flows are unchanged.
ColumnLayout {
    id: root

    required property real centerScale
    required property int centerWidth
    required property var lock

    readonly property Pam pam: lock.pam
    readonly property int cells: 14
    readonly property int typed: pam.buffer.length
    readonly property bool defusing: pam.passwd.active
    readonly property bool failed: pam.state === Pam.Failed || pam.state === Pam.Error
    readonly property bool detonated: pam.state === Pam.MaxTries
    readonly property bool defused: lock.unlocking ?? false
    readonly property color stateColour: {
        if (defused)
            return Valorant.teal;
        if (failed || detonated)
            return Valorant.red;
        if (defusing || pam.howdy.active)
            return Colours.palette.m3primary;
        return Valorant.red;
    }
    readonly property string stateText: {
        if (defused)
            return qsTr("Spike defused");
        if (detonated)
            return qsTr("Spike detonated");
        if (defusing)
            return qsTr("Defusing");
        if (pam.howdy.active)
            return qsTr("Scanning agent");
        if (pam.fprint.active && !typed)
            return qsTr("Spike planted · scan or type");
        if (failed)
            return qsTr("Defuse failed");
        return qsTr("Spike planted");
    }
    property real shake

    spacing: Tokens.spacing.small * centerScale

    focus: true
    onDefusedChanged: {
        if (defused)
            Valorant.play("defuse");
    }
    Component.onCompleted: Valorant.play("plant")
    onActiveFocusChanged: {
        if (!activeFocus)
            forceActiveFocus();
    }

    Keys.onPressed: event => {
        if (root.lock.unlocking)
            return;
        root.pam.handleKey(event);
    }

    // Status header: pulsing spike + state
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        Item {
            implicitWidth: 22 * root.centerScale
            implicitHeight: implicitWidth

            ChamferRect {
                anchors.fill: parent
                chamfer: width / 2
                color: Qt.alpha(root.stateColour, 0.25)
            }

            ChamferRect {
                id: core

                anchors.centerIn: parent
                width: parent.width * 0.45
                height: width
                chamfer: width / 2
                color: root.stateColour

                SequentialAnimation on opacity {
                    running: !root.defused && Valorant.fxIntensity > 0
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.25
                        duration: root.defusing ? 160 : 520
                    }
                    NumberAnimation {
                        to: 1
                        duration: root.defusing ? 160 : 520
                    }
                }
            }
        }

        StyledText {
            animate: true
            text: root.stateText
            color: root.stateColour
            font: Tokens.font.title.builders.large.scale(root.centerScale).build()
        }
    }

    // Defuse bar
    Item {
        id: bar

        Layout.preferredWidth: root.centerWidth * 0.85
        Layout.topMargin: 8 * root.centerScale
        implicitHeight: 46 * root.centerScale

        transform: Translate {
            x: root.shake
        }

        // Half-defuse marker above the bar
        StyledRect {
            x: (parent.width - width) / 2
            y: -7 * root.centerScale
            width: 2
            height: 5 * root.centerScale
            color: Colours.palette.m3onSurfaceVariant
        }

        ChamferRect {
            anchors.fill: parent
            color: Colours.tPalette.m3surfaceContainer
            borderColor: Qt.alpha(root.stateColour, root.failed || root.detonated ? 1 : 0.5)
            borderWidth: 1.5
            chamfer: Valorant.chamfer
            topRight: 0
            bottomLeft: 0
        }

        CornerBrackets {
            inset: -5
            size: 9
            color: Colours.palette.m3outline
        }

        StateLayer {
            hoverEnabled: false
            cursorShape: Qt.IBeamCursor
            onClicked: root.forceActiveFocus()
        }

        MaterialIcon {
            id: authIcon

            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            animate: true
            text: {
                if (root.pam.fprint.active)
                    return "fingerprint";
                if (root.pam.howdy.canAttempt)
                    return "face";
                return root.defused ? "lock_open" : "lock";
            }
            color: root.stateColour
            fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
        }

        Row {
            id: cellRow

            readonly property real cellWidth: (width - spacing * (root.cells - 1)) / root.cells

            anchors.left: authIcon.right
            anchors.right: parent.right
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.large
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.42
            spacing: 3
            opacity: root.typed > 0 || root.defusing || root.defused ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Repeater {
                model: root.cells

                ChamferRect {
                    required property int index
                    readonly property bool lit: root.defused || index < root.typed

                    width: cellRow.cellWidth
                    height: cellRow.height
                    chamfer: 0
                    topRight: height * 0.45
                    bottomLeft: height * 0.45
                    color: lit ? root.stateColour : Qt.alpha(Colours.palette.m3onSurface, 0.08)
                    opacity: root.defusing ? sweep.cellOpacity(index) : 1
                }
            }
        }

        StyledText {
            anchors.left: cellRow.left
            anchors.right: cellRow.right
            anchors.verticalCenter: cellRow.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: root.typed === 0 && !root.defusing && !root.defused
            text: root.detonated ? qsTr("Locked out") : qsTr("Type password to defuse")
            color: Colours.palette.m3outline
            font: Tokens.font.label.builders.large.scale(root.centerScale).build()
        }

        // Overflow counter for passwords longer than the bar
        StyledText {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Tokens.padding.small
            anchors.bottomMargin: 2
            visible: root.typed > root.cells
            text: `+${root.typed - root.cells}`
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }

    // Key hints
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2

        StyledText {
            text: qsTr("Enter ▸ defuse")
            color: Colours.palette.m3outline
            font: Tokens.font.label.builders.small.scale(root.centerScale).build()
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            text: qsTr("Ctrl+⌫ ▸ clear")
            color: Colours.palette.m3outline
            font: Tokens.font.label.builders.small.scale(root.centerScale).build()
        }
    }

    // Sweeping highlight while PAM checks the password
    QtObject {
        id: sweep

        property real pos

        function cellOpacity(i: int): real {
            const d = Math.abs(i - pos * (root.cells + 4) + 2);
            return d < 2.5 ? 1 : 0.35;
        }
    }

    NumberAnimation {
        target: sweep
        property: "pos"
        from: 0
        to: 1
        duration: 900
        loops: Animation.Infinite
        running: root.defusing
    }

    SequentialAnimation {
        id: shakeAnim

        NumberAnimation {
            target: root
            property: "shake"
            to: -10
            duration: 50
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 9
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: -6
            duration: 60
        }
        NumberAnimation {
            target: root
            property: "shake"
            to: 0
            duration: 60
        }
    }

    Connections {
        function onFlashMsg(): void {
            Valorant.play("fail");
            if (Valorant.fxIntensity > 0)
                shakeAnim.restart();
        }

        target: root.pam
    }
}
