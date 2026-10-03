pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

// Window layout switcher. Cycles Hyprland's tiling layouts (SUPER+ALT+T or the bar indicator)
// and keeps the choice across Hyprland config reloads (valo-sync reloads on agent switch).
// Layouts the running Hyprland doesn't know (e.g. "scrolling" on older builds) are skipped.
Singleton {
    id: root

    readonly property var known: ({
            dwindle: {
                label: qsTr("Dwindle"),
                icon: "view_quilt"
            },
            master: {
                label: qsTr("Master"),
                icon: "view_sidebar"
            },
            scrolling: {
                label: qsTr("Scrolling"),
                icon: "view_column"
            },
            monocle: {
                label: qsTr("Monocle"),
                icon: "crop_square"
            }
        })
    readonly property var cycle: Valorant.cfg.layouts ?? ["dwindle", "master", "scrolling"]
    readonly property string current: Hypr.options["general:layout"] ?? "dwindle" // qmllint disable missing-property
    readonly property string label: known[current]?.label ?? current
    readonly property string icon: known[current]?.icon ?? "dashboard"

    property var unsupported: []
    property string pending: ""
    property int attempts: 0
    property bool quiet

    function apply(name: string, silent: bool): void {
        pending = name;
        quiet = !!silent;
        Hypr.extras.applyOptions({
            "general:layout": Hypr.usingLua ? `"${name}"` : name
        });
        verify.restart();
    }

    function set(name: string): void {
        props.chosen = name;
        apply(name);
    }

    function next(): void {
        attempts = 0;
        advance();
    }

    function advance(): void {
        const list = cycle.filter(l => !unsupported.includes(l) || l === current);
        if (list.length < 2)
            return;
        set(list[(list.indexOf(current) + 1) % list.length]);
    }

    PersistentProperties {
        id: props

        property string chosen: ""

        reloadableId: "valoLayout"
    }

    Timer {
        id: verify

        // applyOptions refreshes Hypr.options when Hyprland accepts the change
        interval: 400
        onTriggered: {
            if (root.current === root.pending) {
                if (!root.quiet)
                    Toaster.toast(qsTr("Layout: %1").arg(root.label), qsTr("SUPER+ALT+T to switch"), root.icon);
                return;
            }
            // Rejected: remember and move on to the next layout in the cycle
            if (!root.unsupported.includes(root.pending))
                root.unsupported = [...root.unsupported, root.pending];
            props.chosen = root.current;
            if (++root.attempts < root.cycle.length)
                root.advance();
        }
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.chosen && props.chosen !== root.current)
                root.apply(props.chosen, true);
        }

        target: Hypr
    }

    IpcHandler {
        function next(): string {
            root.next();
            return root.pending;
        }

        function set(name: string): string {
            root.set(name);
            return name;
        }

        function get(): string {
            return root.current;
        }

        target: "layout"
    }
}
