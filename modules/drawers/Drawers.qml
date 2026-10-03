pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.dock

Variants {
    model: Screens.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: content.bar
        }

        ContentWindow {
            id: content

            screen: scope.modelData
            // The frame and its right-side panels stop where the dock starts
            margins.right: dock.reserved
        }

        TaskDock {
            id: dock

            screen: scope.modelData
            hidden: content.hasFullscreen
        }
    }
}
