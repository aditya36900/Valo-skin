pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Windows-style taskbar model for the bar: every open window (minimized ones included, dimmed)
// plus pinned apps. Click = focus / minimize / restore, like the Windows taskbar.
// Pins are desktop entry ids in valorant.json -> taskbar.pinned.
Singleton {
    id: root

    readonly property var pinned: Valorant.cfg.taskbar?.pinned ?? []
    readonly property bool allWorkspaces: Valorant.cfg.taskbar?.allWorkspaces ?? true
    // Window the pointer is over, for the preview popout
    property var hovered: null
    // Windows minimized by "show desktop", restored by the next click
    property var shownDesktop: []

    // Running windows in a stable order (workspace, then when they opened). Anything parked on a
    // hidden special workspace counts as minimized, whoever put it there (SUPER+N, an app's own
    // minimize button, a titlebar plugin, a scratchpad), so nothing open ever goes missing.
    readonly property var windows: {
        const visibleSpecials = Hypr.monitors.values.map(m => m.lastIpcObject?.specialWorkspace?.name ?? "");
        const active = Hyprland.activeToplevel;
        return Hypr.toplevels.values.filter(t => t.lastIpcObject?.mapped !== false).filter(t => {
            const ws = t.workspace?.name ?? "";
            return ws.startsWith("special:") || root.allWorkspaces || t.workspace?.id === Hypr.activeWsId;
        }).map(t => {
            const ws = t.workspace?.name ?? "";
            const minimized = ws.startsWith("special:") && !visibleSpecials.includes(ws);
            const appClass = t.lastIpcObject?.class || t.lastIpcObject?.initialClass || t.wayland?.appId || "";
            return {
                toplevel: t,
                address: t.address,
                appClass: appClass,
                title: t.title || t.lastIpcObject?.initialTitle || appClass,
                minimized: minimized,
                active: !minimized && t === active,
                workspace: t.workspace?.id ?? 0,
                entry: DesktopEntries.heuristicLookup(appClass)
            };
        }).sort((a, b) => a.minimized - b.minimized || (a.workspace < 0) - (b.workspace < 0) || a.workspace - b.workspace); // minimized last
    }

    // Pinned apps first (each followed by its windows), then other running apps, like Windows
    readonly property var items: {
        const out = [];
        const used = new Set();
        for (const id of pinned) {
            const entry = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
            const wins = windows.filter(w => w.entry && entry && w.entry.id === entry.id);
            if (wins.length === 0)
                out.push({
                    pinnedOnly: true,
                    entry: entry,
                    id: id,
                    appClass: id
                });
            for (const w of wins) {
                out.push(Object.assign({
                    pinned: true
                }, w));
                used.add(w.address);
            }
        }
        for (const w of windows)
            if (!used.has(w.address))
                out.push(Object.assign({
                    pinned: false
                }, w));
        return out;
    }

    function dispatchWindow(lua: string, legacy: string, address: string): void {
        Hypr.dispatch(Hypr.usingLua ? lua.replace("%a", `address:0x${address}`) : legacy.replace("%a", `address:0x${address}`));
    }

    function activate(item: var): void {
        if (item.pinnedOnly) {
            item.entry?.execute();
            return;
        }
        if (item.minimized)
            Bench.restore(item.toplevel);
        else if (item.active)
            Bench.minimize(item.address);
        else
            dispatchWindow('hl.dsp.focus({ window = "%a" })', "focuswindow %a", item.address);
    }

    function close(item: var): void {
        if (!item.pinnedOnly)
            dispatchWindow('hl.dsp.window.close({ window = "%a" })', "closewindow %a", item.address);
    }

    function newInstance(item: var): void {
        item.entry?.execute();
    }

    function entryId(item: var): string {
        return item.entry?.id ?? item.appClass ?? "";
    }

    function isPinned(item: var): bool {
        return item.pinnedOnly || pinned.includes(entryId(item));
    }

    // Alt+Tab: next/previous non-minimized window, across workspaces like Plasma's task switcher
    function cycle(step: int): void {
        const list = windows.filter(w => !w.minimized);
        if (list.length === 0)
            return;
        const i = list.findIndex(w => w.active);
        const next = list[((i < 0 ? 0 : i + step) % list.length + list.length) % list.length];
        dispatchWindow('hl.dsp.focus({ window = "%a" })', "focuswindow %a", next.address);
    }

    // Windows' "show desktop": minimize everything on this workspace, or bring it all back
    function showDesktop(): void {
        if (shownDesktop.length > 0) {
            for (const w of windows.filter(w => w.minimized && shownDesktop.includes(w.address)))
                Bench.restore(w.toplevel);
            shownDesktop = [];
            return;
        }
        const here = windows.filter(w => !w.minimized && w.workspace === Hypr.activeWsId);
        shownDesktop = here.map(w => w.address);
        for (const w of here)
            Bench.minimize(w.address);
    }

    function togglePin(item: var): void {
        const id = entryId(item);
        if (!id)
            return;
        Valorant.set("taskbar.pinned", isPinned(item) ? pinned.filter(p => p !== id && p !== item.id) : [...pinned, id]);
    }

    // Fill in window classes (icons, pin ids) right away instead of on the next window event
    Component.onCompleted: Hyprland.refreshToplevels()

    // New and moved windows only get their class/workspace once the toplevel list is re-read
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitlev2", "minimized", "changefloatingmode"].includes(event.name))
                refresh.restart();
        }

        target: Hyprland
    }

    Timer {
        id: refresh

        interval: 150
        onTriggered: Hyprland.refreshToplevels()
    }

    IpcHandler {
        function next(): void {
            root.cycle(1);
        }

        function prev(): void {
            root.cycle(-1);
        }

        function showDesktop(): void {
            root.showDesktop();
        }

        target: "taskbar"
    }
}
