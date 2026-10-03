pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// "The bench": minimized windows. Hyprland has no real minimize, so a window that asks to be
// minimized (its titlebar button, or SUPER+N) is parked on special:minimized. Every window
// sitting on a hidden special workspace shows up in the bar's bench and can be called back.
Singleton {
    id: root

    readonly property string workspace: "special:minimized"
    // Specials currently shown on some monitor don't count as benched
    readonly property var visibleSpecials: Hypr.monitors.values.map(m => m.lastIpcObject?.specialWorkspace?.name ?? "").filter(n => n)
    readonly property var windows: Hypr.toplevels.values.filter(t => {
        const ws = t.workspace?.name ?? "";
        return ws.startsWith("special:") && !visibleSpecials.includes(ws);
    }).sort((a, b) => (b.workspace?.name === workspace) - (a.workspace?.name === workspace))
    property var order: [] // addresses, most recently benched last

    function minimize(address: string): void {
        if (!address)
            return;
        order = [...order.filter(a => a !== address), address];
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${address}", workspace = "${workspace}", follow = false })` : `movetoworkspacesilent ${workspace},address:0x${address}`);
    }

    function minimizeActive(): void {
        const t = Hyprland.activeToplevel;
        if (t && !(t.workspace?.name ?? "").startsWith("special:"))
            minimize(t.address);
    }

    // Hyprland keeps routing clicks to a fullscreen/maximized window even when a floating window is
    // raised over it, so the window looks active but can't be used. Before bringing a window
    // forward, drop that state from the others on the workspace, like Plasma does.
    function clearFullscreen(wsId: int, except: string): void {
        for (const t of Hypr.toplevels.values) {
            if (t.address === except || t.workspace?.id !== wsId || !(t.lastIpcObject?.fullscreen > 0))
                continue;
            if (Hypr.usingLua) {
                Hypr.dispatch(`hl.dsp.window.fullscreen_state({ internal = 0, client = 0, window = "address:0x${t.address}" })`);
            } else {
                Hypr.dispatch(`focuswindow address:0x${t.address}`);
                Hypr.dispatch("fullscreenstate 0 0");
            }
        }
    }

    function restore(toplevel: var): void {
        if (!toplevel)
            return;
        const ws = Hypr.activeWsId;
        order = order.filter(a => a !== toplevel.address);
        clearFullscreen(ws, toplevel.address);
        // follow = true also focuses it
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${toplevel.address}", workspace = "${ws}", follow = true })` : `movetoworkspace ${ws},address:0x${toplevel.address}`);
    }

    function restoreLast(): void {
        for (let i = order.length - 1; i >= 0; i--) {
            const t = windows.find(w => w.address === order[i]);
            if (t)
                return restore(t);
        }
        if (windows.length > 0)
            restore(windows[0]);
    }

    function restoreAll(): void {
        for (const t of [...windows])
            restore(t);
    }

    Connections {
        // Apps' own minimize buttons send "minimized>>ADDRESS,1"
        function onRawEvent(event: HyprlandEvent): void {
            if (event.name !== "minimized")
                return;
            const [address, state] = event.data.split(",");
            if (state === "1")
                root.minimize(address);
        }

        target: Hyprland
    }

    IpcHandler {
        function minimize(): void {
            root.minimizeActive();
        }

        function restore(): void {
            root.restoreLast();
        }

        function restoreAll(): void {
            root.restoreAll();
        }

        function list(): string {
            return root.windows.map(t => `${t.address}\t${t.workspace?.name}\t${t.lastIpcObject?.class ?? ""}\t${t.title}`).join("\n");
        }

        target: "bench"
    }
}
