pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.valorant
import qs.services
import qs.modules.launcher.services

// The launcher as a Valorant buy menu. Apps are sorted into weapon classes by their desktop
// categories, your most-used apps sit in the "Equipped" row, and typing filters everything into
// one result grid. Arrow keys move around, Enter launches.
//
// Exposes the same bits of the ListView API the launcher's search bar drives (currentItem,
// count, increment/decrementCurrentIndex), plus moveHorizontal() for left/right.
Item {
    id: root

    required property SearchBar search
    required property ScreenState screenState
    required property real maxWidth
    required property real maxHeight

    // Weapon classes, in the order they are matched (first match wins)
    readonly property var classes: [
        {
            id: "rifles",
            label: qsTr("Rifles"),
            sub: qsTr("Development"),
            cats: ["Development", "IDE", "TerminalEmulator", "Debugger", "RevisionControl", "Building", "WebDevelopment", "Profiling"]
        },
        {
            id: "heavies",
            label: qsTr("Heavies"),
            sub: qsTr("Media"),
            cats: ["AudioVideo", "Audio", "Video", "Game", "Player", "Recorder", "Music", "TV", "Midi", "Mixer"]
        },
        {
            id: "smgs",
            label: qsTr("SMGs"),
            sub: qsTr("Internet"),
            cats: ["Network", "WebBrowser", "Email", "Chat", "InstantMessaging", "IRCClient", "FileTransfer", "P2P", "News", "RemoteAccess", "Feed"]
        },
        {
            id: "snipers",
            label: qsTr("Snipers"),
            sub: qsTr("Creative"),
            cats: ["Graphics", "Office", "Education", "Science", "Publishing", "Photography", "2DGraphics", "3DGraphics", "RasterGraphics", "VectorGraphics", "Engineering", "Math", "Spreadsheet", "WordProcessor", "Presentation", "ContactManagement", "Calendar"]
        },
        {
            id: "sidearms",
            label: qsTr("Sidearms"),
            sub: qsTr("System"),
            cats: ["System", "Settings", "Monitor", "PackageManager", "HardwareSettings", "DesktopSettings", "Security", "Filesystem"]
        },
        {
            id: "shotguns",
            label: qsTr("Shotguns"),
            sub: qsTr("Utilities"),
            cats: [] // everything else
        }
    ]
    // Display order, like the in-game buy menu
    readonly property var columnOrder: ["sidearms", "smgs", "shotguns", "rifles", "snipers", "heavies"]

    readonly property string query: search.text.trim()
    readonly property bool searching: query.length > 0
    readonly property var allApps: [...Apps.list] // AppEntry, favourites then most used first
    readonly property var frequencies: {
        const map = {};
        for (const a of allApps)
            map[a.id] = a.frequency;
        return map;
    }
    readonly property var equipped: allApps.filter(a => a.frequency > 0).slice(0, equippedCount).map(a => a.entry)
    readonly property var columns: {
        const buckets = {};
        for (const c of classes)
            buckets[c.id] = [];
        const byName = [...allApps].sort((a, b) => a.name.localeCompare(b.name));
        for (const a of byName)
            buckets[classify(a.entry)].push(a.entry);
        return columnOrder.map(id => ({
                    cls: classes.find(c => c.id === id),
                    apps: buckets[id]
                }));
    }
    readonly property var results: searching ? Apps.search(search.text) : []
    readonly property int credits: allApps.reduce((sum, a) => sum + a.frequency, 0)

    readonly property int gap: Tokens.spacing.small
    readonly property int equippedCount: 6
    readonly property real columnWidth: Math.floor(Math.min(210, (maxWidth - Tokens.padding.large * 2 - gap * (columnOrder.length - 1)) / columnOrder.length))
    readonly property real cardHeight: Math.round(Tokens.font.body.medium.pointSize * 4.6)
    readonly property real gridWidth: columnWidth * columnOrder.length + gap * (columnOrder.length - 1)
    // Room left for the class columns' lists under the header, equipped row and column labels
    readonly property real columnsMaxHeight: Math.max(cardHeight, maxHeight - header.height - (equippedBlock.visible ? equippedBlock.height + content.spacing : 0) - Tokens.font.label.large.pointSize * 3 - content.spacing * 2 - Tokens.padding.large * 2)
    readonly property int resultColumns: Math.max(1, Math.floor((gridWidth + gap) / (columnWidth + gap)))

    // Keyboard selection
    property string section: "columns" // "equipped" | "columns"
    property int col: 0
    property int row: 0
    readonly property var currentItem: {
        const entry = searching ? results[row] : section === "equipped" ? equipped[col] : columns[col]?.apps[row];
        return entry ? {
            modelData: entry
        } : null;
    }
    readonly property int count: searching ? results.length : allApps.length

    function classify(entry: var): string {
        const cats = Array.from(entry?.categories ?? []);
        for (const c of classes)
            if (c.cats.some(k => cats.includes(k)))
                return c.id;
        return "shotguns";
    }

    function firstFilledColumn(): int {
        const i = columns.findIndex(c => c.apps.length > 0);
        return Math.max(0, i);
    }

    function resetSelection(): void {
        row = 0;
        if (searching) {
            section = "columns";
            col = 0;
        } else if (equipped.length > 0) {
            section = "equipped";
            col = 0;
        } else {
            section = "columns";
            col = firstFilledColumn();
        }
    }

    function incrementCurrentIndex(): void {
        if (searching) {
            row = Math.min(results.length - 1, row + resultColumns);
        } else if (section === "equipped") {
            section = "columns";
            col = Math.min(col, columns.length - 1);
            row = 0;
        } else {
            row = Math.min((columns[col]?.apps.length ?? 1) - 1, row + 1);
        }
    }

    function decrementCurrentIndex(): void {
        if (searching) {
            row = Math.max(0, row - resultColumns);
        } else if (section === "columns" && row === 0 && equipped.length > 0) {
            section = "equipped";
            col = Math.min(col, equipped.length - 1);
        } else if (section === "columns") {
            row = Math.max(0, row - 1);
        }
    }

    function moveHorizontal(dx: int): void {
        if (searching) {
            row = Math.max(0, Math.min(results.length - 1, row + dx));
        } else if (section === "equipped") {
            col = Math.max(0, Math.min(equipped.length - 1, col + dx));
        } else {
            let c = col;
            do {
                c += dx;
            } while (c >= 0 && c < columns.length && columns[c].apps.length === 0)
            if (c >= 0 && c < columns.length) {
                col = c;
                row = Math.min(row, columns[c].apps.length - 1);
            }
        }
    }

    function launch(entry: var): void {
        Apps.launch(entry);
        screenState.launcher = false;
    }

    onQueryChanged: resetSelection()
    Component.onCompleted: resetSelection()

    implicitWidth: gridWidth + Tokens.padding.large * 2
    implicitHeight: Math.min(maxHeight, content.implicitHeight)

    Column {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.topMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Header: title and "credits" (total launches)
        Item {
            id: header

            width: parent.width
            implicitHeight: title.implicitHeight

            Row {
                spacing: Tokens.spacing.medium

                ChamferRect {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 6
                    implicitHeight: title.implicitHeight * 0.8
                    chamfer: 0
                    bottomRight: 3
                    color: Colours.palette.m3primary
                }

                StyledText {
                    id: title

                    text: root.searching ? qsTr("Armory search") : qsTr("Loadout")
                    font: Tokens.font.title.large
                }

                StyledText {
                    anchors.baseline: title.baseline
                    text: root.searching ? qsTr("%n result(s)", "", root.results.length) : qsTr("Buy phase  //  %n app(s)", "", root.allApps.length)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.small

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Credits")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                ChamferRect {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: creditIcon.implicitHeight * 0.7
                    implicitHeight: implicitWidth
                    chamfer: implicitWidth / 2
                    color: Valorant.gold
                }

                StyledText {
                    id: creditIcon

                    text: root.credits.toLocaleString(Qt.locale(), "f", 0)
                    color: Valorant.gold
                    font: Tokens.font.title.medium
                }
            }
        }

        // Equipped: most used
        Column {
            id: equippedBlock

            visible: !root.searching && root.equipped.length > 0
            width: parent.width
            spacing: Tokens.spacing.extraSmall

            SectionLabel {
                width: parent.width
                label: qsTr("Equipped")
                sub: qsTr("Most used")
            }

            Row {
                spacing: root.gap

                Repeater {
                    model: root.equipped

                    LoadoutCard {
                        required property var modelData
                        required property int index

                        entry: modelData
                        width: (root.gridWidth - root.gap * (root.equippedCount - 1)) / root.equippedCount
                        height: root.cardHeight * 1.15
                        featured: true
                        selected: root.section === "equipped" && root.col === index
                    }
                }
            }
        }

        // Weapon-class columns
        Row {
            visible: !root.searching
            spacing: root.gap

            Repeater {
                model: root.columns

                Column {
                    id: column

                    required property var modelData
                    required property int index

                    width: root.columnWidth
                    spacing: Tokens.spacing.extraSmall

                    SectionLabel {
                        width: parent.width
                        label: column.modelData.cls.label
                        sub: column.modelData.cls.sub
                        count: column.modelData.apps.length
                    }

                    StyledListView {
                        id: columnList

                        width: parent.width
                        height: Math.min(contentHeight, root.columnsMaxHeight)
                        clip: true
                        spacing: root.gap / 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: column.modelData.apps
                        currentIndex: root.section === "columns" && root.col === column.index ? root.row : -1
                        highlightFollowsCurrentItem: false
                        onCurrentIndexChanged: if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: LoadoutCard {
                            required property var modelData
                            required property int index

                            entry: modelData
                            width: columnList.width
                            height: root.cardHeight
                            selected: root.section === "columns" && root.col === column.index && root.row === index
                        }
                    }
                }
            }
        }

        // Search results
        StyledListView {
            id: resultsView

            visible: root.searching
            width: parent.width
            height: Math.min(contentHeight, root.maxHeight - header.height - content.spacing - Tokens.padding.large * 2)
            clip: true
            spacing: root.gap
            boundsBehavior: Flickable.StopAtBounds
            model: Math.ceil(root.results.length / root.resultColumns)
            currentIndex: Math.floor(root.row / root.resultColumns)
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Row {
                id: resultRow

                required property int index

                spacing: root.gap

                Repeater {
                    model: root.results.slice(resultRow.index * root.resultColumns, (resultRow.index + 1) * root.resultColumns)

                    LoadoutCard {
                        required property var modelData
                        required property int index

                        entry: modelData
                        width: root.columnWidth
                        height: root.cardHeight
                        selected: root.row === resultRow.index * root.resultColumns + index
                    }
                }
            }
        }
    }

    component SectionLabel: Item {
        id: sectionLabel

        property string label
        property string sub
        property int count: -1

        implicitWidth: labelRow.implicitWidth
        implicitHeight: labelRow.implicitHeight + Tokens.spacing.extraSmall

        Row {
            id: labelRow

            spacing: Tokens.spacing.small

            StyledText {
                id: labelText

                text: sectionLabel.label
                color: Colours.palette.m3primary
                font: Tokens.font.label.large
            }

            StyledText {
                anchors.baseline: labelText.baseline
                width: Math.max(0, sectionLabel.width - labelText.width - countText.width - Tokens.spacing.small * 2)
                elide: Text.ElideRight
                text: sectionLabel.sub
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }

        StyledText {
            id: countText

            anchors.right: parent.right
            anchors.verticalCenter: labelRow.verticalCenter
            visible: sectionLabel.count >= 0
            text: sectionLabel.count
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Colours.palette.m3outlineVariant
        }
    }

    component LoadoutCard: Item {
        id: card

        property var entry
        property bool selected
        property bool featured
        readonly property bool lit: selected || cardArea.containsMouse
        readonly property int uses: root.frequencies[entry?.id] ?? 0

        ChamferRect {
            anchors.fill: parent
            chamfer: 0
            topLeft: Valorant.chamfer
            bottomRight: Valorant.chamferSmall
            color: card.lit ? Qt.alpha(Colours.palette.m3primary, 0.16) : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            borderColor: card.selected ? Colours.palette.m3primary : card.lit ? Qt.alpha(Colours.palette.m3primary, 0.6) : Colours.palette.m3outlineVariant
            borderWidth: card.selected ? 2 : 1
        }

        // Accent strip along the left edge on selection
        Rectangle {
            x: 0
            y: Valorant.chamfer
            width: 3
            height: parent.height - Valorant.chamfer - 4
            color: Colours.palette.m3primary
            opacity: card.selected ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        IconImage {
            id: cardIcon

            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Math.round(parent.height * (card.featured ? 0.58 : 0.52))
            source: Quickshell.iconPath(card.entry?.icon, "image-missing")
            asynchronous: true
            opacity: card.lit ? 1 : 0.85
        }

        Column {
            anchors.left: parent.left
            anchors.right: cardIcon.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.spacing.small
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.small
            spacing: 0

            StyledText {
                width: parent.width
                text: card.entry?.name ?? ""
                elide: Text.ElideRight
                color: card.lit ? Colours.palette.m3primary : Colours.palette.m3onSurface
                font: card.featured ? Tokens.font.title.small : Tokens.font.label.large
            }

            Row {
                width: parent.width
                spacing: Tokens.spacing.extraSmall

                // "Price": how often you've launched it
                ChamferRect {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: card.uses > 0
                    implicitWidth: 8
                    implicitHeight: 8
                    chamfer: 4
                    color: Valorant.gold
                }

                StyledText {
                    id: priceText

                    visible: card.uses > 0
                    text: card.uses
                    color: Valorant.gold
                    font: Tokens.font.label.small
                }

                StyledText {
                    width: parent.width - (card.uses > 0 ? priceText.width + 6 + parent.spacing * 2 : 0)
                    text: card.entry?.genericName || card.entry?.comment || ""
                    elide: Text.ElideRight
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        MouseArea {
            id: cardArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.launch(card.entry)
        }
    }
}
