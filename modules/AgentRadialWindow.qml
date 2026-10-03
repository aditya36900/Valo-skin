pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import qs.components.containers
import qs.components.valorant
import qs.services

// Full-screen layer for the agent quick-switch ring (Valorant.radialOpen; IPC "valorant radial")
Scope {
    LazyLoader {
        active: Valorant.radialOpen && Valorant.enabled

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "valorant-radial"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                AgentRadial {
                    anchors.fill: parent
                    onClosed: Valorant.radialOpen = false
                }
            }
        }
    }
}
