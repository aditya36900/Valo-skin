pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia

// "Night Ops": blue-light filter on hyprsunset.
//   mode "off" | "on" | "schedule" (start..end, default 19:30-06:30) | "sun" (local sunset to
//   sunrise from the weather service, schedule as fallback)
// The quick toggle overrides the schedule until its next boundary. Settings live in
// valorant.json -> nightOps.
Singleton {
    id: root

    readonly property var cfg: Valorant.cfg.nightOps ?? ({})
    readonly property string mode: cfg.mode ?? "schedule"
    readonly property int temperature: Math.max(1500, Math.min(6500, cfg.temperature ?? 4000))
    readonly property string start: cfg.start ?? "19:30"
    readonly property string end: cfg.end ?? "06:30"

    property bool available: true
    property date now: new Date()
    // Manual override from the quick toggle: null (follow schedule), true or false
    property var override: null
    property bool overrideAt // the scheduled state when the override was set

    readonly property bool scheduled: {
        if (mode === "on")
            return true;
        if (mode === "off")
            return false;
        const [s, e] = window();
        const m = now.getHours() * 60 + now.getMinutes();
        return s <= e ? m >= s && m < e : m >= s || m < e;
    }
    readonly property bool active: override !== null ? override : scheduled

    function minutes(hhmm: string): int {
        const [h, m] = hhmm.split(":").map(n => parseInt(n, 10));
        return ((h || 0) * 60 + (m || 0)) % 1440;
    }

    // [start, end] in minutes after midnight
    function window(): list<int> {
        if (mode === "sun" && Weather.cc?.sunset && Weather.cc?.sunrise) {
            const ss = new Date(Weather.cc.sunset);
            const sr = new Date(Weather.cc.sunrise);
            return [ss.getHours() * 60 + ss.getMinutes(), sr.getHours() * 60 + sr.getMinutes()];
        }
        return [minutes(start), minutes(end)];
    }

    function toggle(): void {
        override = !active;
        overrideAt = scheduled;
        Toaster.toast(active ? qsTr("Night Ops engaged") : qsTr("Night Ops off"), active ? qsTr("Screen warmed to %1K").arg(temperature) : qsTr("Colours back to normal"), active ? "nightlight" : "light_mode");
    }

    function setMode(m: string): void {
        override = null;
        Valorant.set("nightOps.mode", m);
    }

    function setTemperature(k: int): void {
        Valorant.set("nightOps.temperature", Math.round(k / 100) * 100);
    }

    // The override ends when the schedule next flips
    onScheduledChanged: if (override !== null && scheduled !== overrideAt)
        override = null
    onActiveChanged: debounce.restart()
    onTemperatureChanged: if (active)
        debounce.restart()
    Component.onCompleted: debounce.restart()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // Restarting hyprsunset is the most portable way to change temperature (no IPC version quirks)
    Timer {
        id: debounce

        interval: 350
        onTriggered: {
            proc.running = false;
            proc.running = root.active && root.available;
        }
    }

    Process {
        id: proc

        command: ["sh", "-c", 'command -v hyprsunset >/dev/null || exit 3; exec hyprsunset -t "$1"', "night-ops", `${root.temperature}`]
        onExited: code => {
            if (code === 3) {
                root.available = false;
                Toaster.toast(qsTr("Night Ops unavailable"), qsTr("Install hyprsunset"), "nightlight");
            }
        }
    }

    IpcHandler {
        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.override = true;
            root.overrideAt = root.scheduled;
        }

        function disable(): void {
            root.override = false;
            root.overrideAt = root.scheduled;
        }

        function mode(m: string): string {
            root.setMode(m);
            return m;
        }

        function temperature(k: int): void {
            root.setTemperature(k);
        }

        function status(): string {
            return `${root.active ? "on" : "off"} ${root.temperature}K mode=${root.mode}`;
        }

        target: "nightops"
    }
}
