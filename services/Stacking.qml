pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Keeps floating windows usable over maximized/fullscreen ones.
//
// Hyprland only lets a floating window take clicks over a maximized/fullscreen window while it is
// flagged "allowed over fullscreen". Focusing the maximized window clears that flag, yet the
// floating window can stay drawn on top: it looks active but every click lands on the window
// behind (open a dialog over a maximized browser, click the browser, click back: stuck).
// Whenever focus moves on a workspace that has a maximized/fullscreen window, raise that
// workspace's floating windows again (alter_zorder top restores the flag), so what you see on
// top is always what you click, like Plasma.
Singleton {
    id: root

    function fix(): void {
        const tops = Hypr.toplevels.values;
        const active = Hyprland.activeToplevel;
        const wsId = active?.workspace?.id;
        if (wsId === undefined || active?.lastIpcObject?.floating)
            return;
        const ws = Hypr.workspaces.values.find(w => w.id === wsId);
        const hasFs = ws?.lastIpcObject?.hasfullscreen || tops.some(t => t.workspace?.id === wsId && t.lastIpcObject?.fullscreen > 0);
        if (!hasFs)
            return;
        for (const t of tops) {
            const o = t.lastIpcObject;
            if (t === active || t.workspace?.id !== wsId || !o?.floating || o.mapped === false || o.hidden)
                continue;
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.alter_zorder({ mode = "top", window = "address:0x${t.address}" })` : `alterzorder top,address:0x${t.address}`);
        }
    }

    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (["activewindowv2", "fullscreen", "changefloatingmode", "openwindow", "movewindowv2"].includes(event.name)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
                settle.restart();
            }
        }

        target: Hyprland
    }

    // Let the refreshed client/workspace state arrive before deciding
    Timer {
        id: settle

        interval: 120
        onTriggered: root.fix()
    }
}
