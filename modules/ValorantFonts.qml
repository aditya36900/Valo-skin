import QtQuick
import Quickshell

// Bundled Valorant-style fonts (SIL OFL / Apache 2.0), so the theme works without system installs
Scope {
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/BebasNeue-Regular.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/Oswald-Variable.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/Barlow-Regular.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/Barlow-Medium.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/Barlow-SemiBold.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/Barlow-Bold.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/MaterialSymbolsSharp.ttf")
    }
}
