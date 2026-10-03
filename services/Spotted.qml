pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// "Spotted": privacy indicators. Polls valo-spotted (PipeWire + /dev/video*) for apps using the
// microphone, camera or screen, for the red pips in the bar.
Singleton {
    id: root

    readonly property bool enabled: Valorant.cfg.spotted ?? true
    property var mic: []
    property var camera: []
    property var screen: []
    readonly property bool any: mic.length > 0 || camera.length > 0 || screen.length > 0

    Process {
        id: proc

        command: ["sh", "-c", 'PATH="$PATH:$HOME/.local/bin"; command -v valo-spotted >/dev/null && exec valo-spotted']
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.mic = s.mic ?? [];
                    root.camera = s.camera ?? [];
                    root.screen = s.screen ?? [];
                } catch (e) {
                    root.mic = [];
                    root.camera = [];
                    root.screen = [];
                }
            }
        }
    }

    Timer {
        interval: root.any ? 2000 : 3000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running)
            proc.running = true
    }
}
