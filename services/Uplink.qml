pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

// "Uplink": your phone on the desktop through KDE Connect (valo-uplink helper). Phone
// notifications and calls arrive as normal desktop notifications (kill banners, styled as uplink
// banners); this service adds device status and actions for the bar and its popout.
Singleton {
    id: root

    property bool installed
    property bool running
    property var devices: []
    // The phone shown in the bar: first reachable + paired device
    readonly property var phone: devices.find(d => d.reachable && d.paired) ?? null
    readonly property bool connected: phone !== null
    property string lastAction
    property bool busy

    function helper(args: list<string>): list<string> {
        return ["sh", "-c", 'PATH="$PATH:$HOME/.local/bin"; exec "$0" "$@"', "valo-uplink", ...args];
    }

    function refresh(): void {
        if (!statusProc.running)
            statusProc.running = true;
    }

    function action(name: string, args: list<string>): void {
        const dev = phone ?? devices.find(d => d.reachable);
        if (!dev)
            return;
        lastAction = name;
        actionProc.command = helper([name, dev.id, ...(args ?? [])]);
        actionProc.running = true;
    }

    function ring(): void {
        action("ring", []);
    }

    function ping(): void {
        action("ping", []);
    }

    function sendScreenshot(): void {
        action("screenshot", []);
    }

    function sendClipboard(): void {
        action("clipboard", []);
    }

    function browse(): void {
        action("browse", []);
    }

    // File picker (kdialog / zenity / portal-less fallback) then send
    function pickAndShare(): void {
        action("pickshare", []);
    }

    function share(files: list<string>): void {
        action("share", files);
    }

    function sms(number: string, text: string): void {
        if (number.trim() && text.trim())
            action("sms", [number.trim(), text]);
    }

    function pair(id: string): void {
        actionProc.command = helper(["pair", id]);
        lastAction = "pair";
        actionProc.running = true;
    }

    function openApp(): void {
        Quickshell.execDetached(["sh", "-c", "command -v kdeconnect-app >/dev/null && exec kdeconnect-app || exec kdeconnect-settings"]);
    }

    function openSms(): void {
        Quickshell.execDetached(["kdeconnect-sms"]);
    }

    Process {
        id: statusProc

        command: root.helper(["status"])
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.installed = s.installed;
                    root.running = s.running;
                    root.devices = s.devices ?? [];
                } catch (e) {
                    root.installed = false;
                    root.devices = [];
                }
            }
        }
    }

    Process {
        id: actionProc

        onRunningChanged: root.busy = running
        onExited: (code, status) => {
            const labels = {
                ring: qsTr("Ringing your phone"),
                ping: qsTr("Ping sent"),
                screenshot: qsTr("Screenshot sent to your phone"),
                clipboard: qsTr("Clipboard sent to your phone"),
                browse: qsTr("Phone storage opened"),
                share: qsTr("Files sent to your phone"),
                pickshare: qsTr("Files sent to your phone"),
                sms: qsTr("Message sent"),
                pair: qsTr("Pairing request sent: accept it on your phone")
            };
            if (code === 0)
                Toaster.toast(qsTr("Uplink"), labels[root.lastAction] ?? qsTr("Done"), "smartphone");
            else
                Toaster.toast(qsTr("Uplink failed"), qsTr("Is the phone connected? (%1)").arg(root.lastAction), "phonelink_erase");
            root.refresh();
        }
    }

    Timer {
        // Phone battery/signal; cheap D-Bus reads
        interval: root.connected ? 30000 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        function ring(): void {
            root.ring();
        }

        function screenshot(): void {
            root.sendScreenshot();
        }

        function clipboard(): void {
            root.sendClipboard();
        }

        function status(): string {
            return JSON.stringify(root.phone ?? {});
        }

        target: "uplink"
    }
}
