import QtQuick
import qs.services

// The current agent's portrait over the wallpaper, like the in-game agent screen: their name art
// faint behind, the portrait on the right, sliding in on lock-in. Art comes from
// `valo-agent-art` (~/.local/share/valo-skin/agent-art/); nothing shows until it's downloaded.
Item {
    id: root

    readonly property string agent: Valorant.agent
    readonly property string portrait: Valorant.agentArtFile(agent, "")
    readonly property string nameArt: Valorant.agentArtFile(agent, "name")

    anchors.fill: parent
    visible: Valorant.agentArt && agent !== "valorant" && art.status === Image.Ready

    // Stylised name art, tall and faint behind the portrait
    Image {
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.04
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height * 0.95
        fillMode: Image.PreserveAspectFit
        source: root.nameArt
        asynchronous: true
        cache: false
        opacity: status === Image.Ready ? 0.22 : 0
    }

    Image {
        id: art

        property real slide: 0

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.02 - slide
        height: parent.height * 0.98
        fillMode: Image.PreserveAspectFit
        source: root.portrait
        asynchronous: true
        cache: false
        mipmap: true

        onStatusChanged: if (status === Image.Ready)
            enter.restart()

        ParallelAnimation {
            id: enter

            NumberAnimation {
                target: art
                property: "opacity"
                from: 0
                to: 1
                duration: 450
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: art
                property: "slide"
                from: root.width * 0.06
                to: 0
                duration: 600
                easing.type: Easing.OutCubic
            }
        }
    }

    // Art downloaded while the shell is running shows up without a restart
    Timer {
        interval: 20000
        repeat: true
        running: Valorant.agentArt && root.agent !== "valorant" && art.status === Image.Error
        onTriggered: {
            art.source = "";
            art.source = Qt.binding(() => root.portrait);
        }
    }
}
