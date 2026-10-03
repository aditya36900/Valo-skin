import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();

        // Valo-skin: background watchers and IPC targets (keybinds) must exist from login
        Bench;
        TaskbarState;
        Stacking;
        Layouts;
        Stash;
        NightOps;
        Uplink;
        Spotted;
        PatchNotes;

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
