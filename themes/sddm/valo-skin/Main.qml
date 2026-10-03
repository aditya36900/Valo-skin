// Valo-skin SDDM theme: Valorant main-menu style login.
// Uses SDDM's context objects: sddm, userModel, sessionModel, config, keyboard.
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    readonly property color accent: config.accent || "#ff4655"
    readonly property color navy: "#0f1923"
    readonly property color white: "#ece8e1"
    readonly property color red: "#ff4655"
    readonly property color teal: "#17d1a6"
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string userName: userList.currentItem ? userList.currentItem.name : ""
    property string state_: "idle" // idle | defusing | failed | defused

    function login(): void {
        if (password.text.length === 0 && !userList.currentItem)
            return;
        state_ = "defusing";
        sddm.login(userName, password.text, sessionIndex);
    }

    width: 1920
    height: 1080

    Connections {
        function onLoginFailed(): void {
            root.state_ = "failed";
            password.text = "";
            shake.restart();
        }

        function onLoginSucceeded(): void {
            root.state_ = "defused";
        }

        target: sddm
    }

    FontLoader {
        id: bebas

        source: "assets/BebasNeue-Regular.ttf"
    }

    FontLoader {
        id: oswald

        source: "assets/Oswald-Variable.ttf"
    }

    FontLoader {
        id: barlow

        source: "assets/Barlow-Regular.ttf"
    }

    FontLoader {
        id: icons

        source: "assets/MaterialSymbolsSharp.ttf"
    }

    Image {
        anchors.fill: parent
        source: config.background || "assets/background.webp"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Menu side panel
    Rectangle {
        id: panel

        width: Math.max(520, root.width * 0.3)
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(root.navy, 0.96)
            }
            GradientStop {
                position: 0.8
                color: Qt.alpha(root.navy, 0.88)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(root.navy, 0)
            }
        }
    }

    Rectangle {
        x: panel.width * 0.12 - 18
        y: root.height * 0.14
        width: 4
        height: root.height * 0.72
        color: Qt.alpha(root.accent, 0.5)
    }

    Column {
        id: menu

        x: panel.width * 0.12
        y: root.height * 0.1
        width: panel.width * 0.72
        spacing: Math.round(root.height * 0.014)

        // Emblem
        Shape {
            width: 96
            height: 68
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.white
                strokeColor: "transparent"

                PathSvg {
                    path: "M16.5,6 L6,16.5 L6,51.3 L16.5,61.8 L22.5,61.8 L22.5,57.3 L18.4,57.3 L10.5,49.4 L10.5,18.4 L18.4,10.5 L22.5,10.5 L22.5,6 Z M79.5,6 L90,16.5 L90,51.3 L79.5,61.8 L73.5,61.8 L73.5,57.3 L77.6,57.3 L85.5,49.4 L85.5,18.4 L77.6,10.5 L73.5,10.5 L73.5,6 Z"
                }
            }

            ShapePath {
                fillColor: root.accent
                strokeColor: "transparent"

                PathSvg {
                    path: "M25.5,32.3 L39,32.3 L39,35.6 L25.5,35.6 Z M57,32.3 L70.5,32.3 L70.5,35.6 L57,35.6 Z M46.4,11.3 L49.7,11.3 L49.7,24.8 L46.4,24.8 Z M46.4,43 L49.7,43 L49.7,56.5 L46.4,56.5 Z M46.4,32.3 L49.7,32.3 L49.7,35.6 L46.4,35.6 Z"
                }
            }
        }

        Text {
            text: (config.headline || "VALO-SKIN").toUpperCase()
            color: root.white
            font.family: bebas.name
            font.pixelSize: Math.min(96, root.height * 0.085)
            font.letterSpacing: 4
        }

        Text {
            text: (config.agentName || "Valorant").toUpperCase() + "  //  " + Qt.formatDateTime(clock.now, "dddd d MMMM").toUpperCase()
            color: Qt.alpha(root.white, 0.7)
            font.family: oswald.name
            font.pixelSize: 20
            font.letterSpacing: 3
        }

        Item {
            width: 1
            height: root.height * 0.02
        }

        Text {
            text: "SELECT AGENT"
            color: Qt.alpha(root.white, 0.55)
            font.family: barlow.name
            font.pixelSize: 15
            font.letterSpacing: 2
        }

        ListView {
            id: userList

            width: parent.width
            height: Math.min(count, 3) * 58
            clip: true
            model: userModel
            currentIndex: root.userIndex
            spacing: 6
            interactive: count > 3

            delegate: Item {
                id: userRow

                required property int index
                required property string name
                required property string realName
                readonly property bool selected: ListView.isCurrentItem

                width: userList.width
                height: 52

                Chamfer {
                    anchors.fill: parent
                    fill: userRow.selected ? Qt.alpha(root.accent, 0.22) : Qt.alpha(root.white, 0.05)
                    stroke: userRow.selected ? root.accent : Qt.alpha(root.white, 0.15)
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: (userRow.name === config.playerUser && config.playerName ? config.playerName : userRow.realName || userRow.name).toUpperCase()
                    color: userRow.selected ? root.white : Qt.alpha(root.white, 0.7)
                    font.family: oswald.name
                    font.pixelSize: 22
                    font.letterSpacing: 2
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    visible: userRow.selected
                    text: "LOCKED IN"
                    color: root.accent
                    font.family: barlow.name
                    font.pixelSize: 13
                    font.letterSpacing: 2
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.userIndex = userRow.index;
                        password.forceActiveFocus();
                    }
                }
            }
        }

        Item {
            width: 1
            height: root.height * 0.006
        }

        Text {
            text: root.state_ === "failed" ? "DEFUSE FAILED" : root.state_ === "defusing" ? "DEFUSING" : root.state_ === "defused" ? "SPIKE DEFUSED" : "SPIKE PLANTED"
            color: root.state_ === "defused" ? root.teal : root.state_ === "defusing" ? root.accent : root.red
            font.family: oswald.name
            font.pixelSize: 26
            font.letterSpacing: 3
        }

        // Defuse bar password field
        Item {
            id: bar

            property real shakeX

            width: parent.width
            height: 58

            transform: Translate {
                x: bar.shakeX
            }

            Chamfer {
                anchors.fill: parent
                fill: Qt.alpha(root.white, 0.06)
                stroke: root.state_ === "failed" ? root.red : Qt.alpha(root.accent, 0.7)
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 4
                visible: password.text.length > 0 || root.state_ === "defused"

                Repeater {
                    model: 14

                    Rectangle {
                        required property int index

                        width: (parent.width - 13 * 4) / 14
                        height: 22
                        color: root.state_ === "defused" ? root.teal : index < password.text.length ? root.accent : Qt.alpha(root.white, 0.1)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0 && root.state_ !== "defused"
                text: "TYPE PASSWORD TO DEFUSE"
                color: Qt.alpha(root.white, 0.45)
                font.family: barlow.name
                font.pixelSize: 17
                font.letterSpacing: 2
            }

            TextInput {
                id: password

                anchors.fill: parent
                opacity: 0
                echoMode: TextInput.Password
                focus: true
                onAccepted: root.login()
                onTextChanged: {
                    if (root.state_ === "failed")
                        root.state_ = "idle";
                }
                Keys.onUpPressed: root.userIndex = Math.max(0, root.userIndex - 1)
                Keys.onDownPressed: root.userIndex = Math.min(userList.count - 1, root.userIndex + 1)
            }
        }

        Row {
            spacing: 12

            MenuButton {
                label: "DEFUSE"
                primary: true
                onClicked: root.login()
            }

            MenuButton {
                label: (sessionList.currentText || "SESSION").toUpperCase()
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessionModel.rowCount())
            }
        }

        Text {
            text: (keyboard.capsLock ? "CAPS LOCK ON  ·  " : "") + "SESSION: " + (sessionList.currentText || "").toUpperCase() + "   ·   CLICK SESSION TO CYCLE"
            color: keyboard.capsLock ? root.red : Qt.alpha(root.white, 0.4)
            font.family: barlow.name
            font.pixelSize: 13
            font.letterSpacing: 1.5
        }
    }

    // Session names resolved from the model for display
    Repeater {
        id: sessionList

        // `count` makes the binding re-evaluate once delegates exist
        readonly property string currentText: count > 0 && itemAt(root.sessionIndex) ? itemAt(root.sessionIndex).sessionName : ""

        model: sessionModel

        delegate: Item {
            required property string name

            readonly property string sessionName: name
        }
    }

    // Bottom-right: power
    Row {
        anchors.right: parent.right
        anchors.rightMargin: root.height * 0.06
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.height * 0.07
        spacing: 12

        MenuButton {
            label: "QUIT"
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }

        MenuButton {
            label: "REMATCH"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }

        MenuButton {
            label: "STANDBY"
            visible: sddm.canSuspend
            onClicked: sddm.suspend()
        }
    }

    // Top-right clock styled as the round timer
    Column {
        id: clock

        property date now: new Date()

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.height * 0.06

        Text {
            anchors.right: parent.right
            text: Qt.formatTime(clock.now, "hh:mm")
            color: root.white
            font.family: bebas.name
            font.pixelSize: 110
            font.letterSpacing: 4
        }

        Rectangle {
            anchors.right: parent.right
            width: 220 * (60 - clock.now.getSeconds()) / 60
            height: 4
            color: clock.now.getSeconds() >= 50 ? root.red : root.accent
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.now = new Date()
        }
    }

    SequentialAnimation {
        id: shake

        NumberAnimation {
            target: bar
            property: "shakeX"
            to: -12
            duration: 50
        }
        NumberAnimation {
            target: bar
            property: "shakeX"
            to: 10
            duration: 70
        }
        NumberAnimation {
            target: bar
            property: "shakeX"
            to: -6
            duration: 60
        }
        NumberAnimation {
            target: bar
            property: "shakeX"
            to: 0
            duration: 60
        }
    }

    component Chamfer: Shape {
        id: ch

        property color fill
        property color stroke
        property real cut: 12

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: ch.fill
            strokeColor: ch.stroke
            strokeWidth: 1.5
            joinStyle: ShapePath.MiterJoin
            startX: ch.cut
            startY: 0.75

            PathLine {
                x: ch.width - 0.75
                y: 0.75
            }
            PathLine {
                x: ch.width - 0.75
                y: ch.height - ch.cut
            }
            PathLine {
                x: ch.width - ch.cut
                y: ch.height - 0.75
            }
            PathLine {
                x: 0.75
                y: ch.height - 0.75
            }
            PathLine {
                x: 0.75
                y: ch.cut
            }
            PathLine {
                x: ch.cut
                y: 0.75
            }
        }
    }

    component MenuButton: Item {
        id: btn

        property string label
        property bool primary

        signal clicked

        width: Math.max(150, txt.implicitWidth + 48)
        height: 48

        Chamfer {
            anchors.fill: parent
            cut: 10
            fill: btn.primary ? root.accent : mouse.containsMouse ? Qt.alpha(root.white, 0.14) : Qt.alpha(root.white, 0.06)
            stroke: btn.primary ? root.accent : Qt.alpha(root.white, 0.25)
        }

        Text {
            id: txt

            anchors.centerIn: parent
            text: btn.label
            color: btn.primary ? root.navy : root.white
            font.family: oswald.name
            font.pixelSize: 18
            font.letterSpacing: 2
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
