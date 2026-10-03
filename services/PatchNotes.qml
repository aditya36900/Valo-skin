pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

// "Patch Notes": pending system, Flatpak and firmware updates (valo-updates helper), checked
// at start and every few hours. "Update all" opens a terminal running the updates.
Singleton {
    id: root

    readonly property bool enabled: Valorant.cfg.patchNotes?.enabled ?? true
    readonly property int intervalHours: Valorant.cfg.patchNotes?.intervalHours ?? 3
    property var system: []
    property var flatpak: []
    property var firmware: []
    property var aur: []
    property string manager
    property date lastChecked
    property bool checking: proc.running
    readonly property int total: system.length + flatpak.length + firmware.length + aur.length
    property int notifiedTotal

    function check(): void {
        if (!proc.running)
            proc.running = true;
    }

    function applyAll(): void {
        Quickshell.execDetached([...GlobalConfig.general.apps.terminal, "sh", "-c", 'PATH="$PATH:$HOME/.local/bin"; valo-updates apply']);
    }

    Process {
        id: proc

        command: ["sh", "-c", 'PATH="$PATH:$HOME/.local/bin"; command -v valo-updates >/dev/null && exec valo-updates check']
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.system = s.system ?? [];
                    root.flatpak = s.flatpak ?? [];
                    root.firmware = s.firmware ?? [];
                    root.aur = s.aur ?? [];
                    root.manager = s.manager ?? "";
                    root.lastChecked = new Date();
                    if (root.total > root.notifiedTotal && root.total > 0)
                        Toaster.toast(qsTr("Patch notes"), qsTr("%n update(s) ready", "", root.total), "system_update_alt");
                    root.notifiedTotal = root.total;
                } catch (e) {}
            }
        }
    }

    Timer {
        // First check shortly after login, then every few hours
        interval: root.lastChecked.getTime() ? root.intervalHours * 3600000 : 90000
        running: root.enabled
        repeat: true
        onTriggered: root.check()
    }

    IpcHandler {
        function check(): void {
            root.check();
        }

        function count(): int {
            return root.total;
        }

        function apply(): void {
            root.applyAll();
        }

        target: "updates"
    }
}
