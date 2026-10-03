pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.utils

// Launcher ">agent" mode: search and lock in Valorant agent themes
Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}agent `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.role}`;
    }

    list: agents.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "role"]
    weights: [0.9, 0.1]

    Variants {
        id: agents

        model: Valorant.agentIds

        Agent {}
    }

    component Agent: QtObject {
        required property string modelData
        readonly property string agentId: modelData
        readonly property string name: Valorant.agents[modelData].name
        readonly property string role: Valorant.agents[modelData].role
        readonly property color accent: Valorant.agents[modelData].accent
        readonly property string roleIcon: {
            switch (role) {
            case "Duelist":
                return "swords";
            case "Initiator":
                return "radar";
            case "Controller":
                return "cloud";
            case "Sentinel":
                return "shield";
            default:
                return "my_location";
            }
        }

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            Valorant.setAgent(agentId);
        }
    }
}
