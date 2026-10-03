pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.utils

// "Stash": clipboard history on cliphist. Keeps a wl-paste watcher running (text and images),
// lists entries for the launcher's ">clip" mode, and keeps pinned entries in a separate file so
// clearing the history never loses them. SUPER+V opens it.
Singleton {
    id: root

    readonly property bool enabled: Valorant.cfg.stash?.enabled ?? true
    readonly property string pinsFile: `${Paths.data}/stash-pins.json`
    readonly property string cacheDir: `${Paths.cache}/stash`
    property bool available: true
    property var entries: [] // { id, preview, image }
    property var pins: [] // { text } or { image: path }
    // Text to put in the launcher's search box the next time it opens (used by SUPER+V)
    property string pendingQuery

    function sh(script: string, args: list<string>): list<string> {
        return ["sh", "-c", script, "valo-stash", ...args];
    }

    function refresh(): void {
        if (!listProc.running)
            listProc.running = true;
    }

    function query(text: string): var {
        const q = text.replace(/^\S+\s?/, "").toLowerCase(); // drop the ">clip" prefix
        const pinned = pins.map((p, i) => ({
                    kind: "pin",
                    index: i,
                    preview: p.text ?? "",
                    image: !!p.image,
                    path: p.image ?? "",
                    pinned: true
                }));
        const hist = entries.map(e => Object.assign({
                kind: "entry",
                pinned: false
            }, e));
        const all = [...pinned, ...hist];
        const out = q ? all.filter(e => !e.image && e.preview.toLowerCase().includes(q)) : all;
        return out.map(e => Object.assign(e, {
                onClicked: list => {
                    root.copy(e);
                    list.screenState.launcher = false;
                }
            }));
    }

    function copy(e: var): void {
        if (e.kind === "pin" && e.image)
            Quickshell.execDetached(sh('wl-copy < "$1"', [e.path]));
        else if (e.kind === "pin")
            Quickshell.execDetached(["wl-copy", "--", e.preview]);
        else
            Quickshell.execDetached(sh('cliphist decode "$1" | wl-copy', [e.id]));
    }

    function remove(e: var): void {
        if (e.kind === "pin") {
            if (e.image)
                Quickshell.execDetached(["rm", "-f", "--", e.path]);
            pins = pins.filter((_, i) => i !== e.index);
            savePins();
            return;
        }
        entries = entries.filter(x => x.id !== e.id);
        Quickshell.execDetached(sh('printf "%s\\t%s" "$1" "$2" | cliphist delete', [e.id, e.preview]));
    }

    function pin(e: var): void {
        if (e.kind === "pin")
            return;
        pinProc.entry = e;
        pinProc.command = e.image ? sh('mkdir -p "$2" && f="$2/pin-$(date +%s%N).png" && cliphist decode "$1" > "$f" && echo "$f"', [e.id, `${Paths.data}/stash-pins`]) : sh('cliphist decode "$1"', [e.id]);
        pinProc.running = true;
    }

    function wipe(): void {
        entries = [];
        Quickshell.execDetached(["cliphist", "wipe"]);
        Toaster.toast(qsTr("Stash cleared"), qsTr("Pinned items were kept"), "delete_sweep");
    }

    function thumbnail(id: string): string {
        return `${cacheDir}/${id}.png`;
    }

    function savePins(): void {
        pinsView.setText(JSON.stringify(pins, null, 2) + "\n");
    }

    // Watchers: text and images into cliphist
    Process {
        running: root.enabled
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-paste >/dev/null || exit 3; exec wl-paste --type text --watch cliphist store"]
        onExited: code => {
            if (code === 3)
                root.available = false;
        }
    }

    Process {
        running: root.enabled && root.available
        command: ["sh", "-c", "exec wl-paste --type image --watch cliphist store"]
    }

    Process {
        id: listProc

        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 3; cliphist list | head -n 300"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1)
                        continue;
                    const preview = line.slice(tab + 1);
                    out.push({
                        id: line.slice(0, tab),
                        preview: preview,
                        image: /^\[\[ binary data .* (png|jpe?g|webp|gif|bmp)/i.test(preview)
                    });
                }
                root.entries = out;
            }
        }
        onExited: code => root.available = code !== 3
    }

    Process {
        id: pinProc

        property var entry

        stdout: StdioCollector {
            onStreamFinished: {
                const e = pinProc.entry;
                const value = e.image ? text.trim() : text;
                if (!value)
                    return;
                root.pins = [e.image ? {
                        image: value
                    } : {
                        text: value
                    }, ...root.pins];
                root.savePins();
                Toaster.toast(qsTr("Pinned to stash"), e.image ? qsTr("Image") : value.slice(0, 60), "keep");
            }
        }
    }

    FileView {
        id: pinsView

        path: root.pinsFile
        printErrors: false
        onLoaded: {
            try {
                root.pins = JSON.parse(text()) ?? [];
            } catch (e) {
                root.pins = [];
            }
        }
    }

    IpcHandler {
        function open(): void {
            root.refresh();
            root.pendingQuery = `${GlobalConfig.launcher.actionPrefix}clip `;
            const s = ShellState.forActive();
            if (s)
                s.launcher = true;
        }

        function wipe(): void {
            root.wipe();
        }

        target: "stash"
    }
}
