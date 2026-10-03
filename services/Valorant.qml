pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Valorant theme state. Backed by ~/.config/caelestia/valorant.json, which is
// created with defaults on first launch and hot-reloaded on change.
Singleton {
    id: root

    // Base Valorant palette
    readonly property color red: paletteCfg.red ?? "#ff4655"
    readonly property color navy: paletteCfg.navy ?? "#0f1923"
    readonly property color white: paletteCfg.white ?? "#ece8e1"
    readonly property color teal: paletteCfg.teal ?? "#17d1a6"
    readonly property color gold: paletteCfg.gold ?? "#e8c06a"
    readonly property color black: paletteCfg.black ?? "#0a0e12"

    // Agent signature accents. Original approximations, not official assets.
    readonly property var agents: ({
            valorant: {
                name: "Valorant",
                role: "Default",
                accent: "#ff4655"
            },
            astra: {
                name: "Astra",
                role: "Controller",
                accent: "#a35cff"
            },
            breach: {
                name: "Breach",
                role: "Initiator",
                accent: "#ff7b2e"
            },
            brimstone: {
                name: "Brimstone",
                role: "Controller",
                accent: "#ff9f43"
            },
            chamber: {
                name: "Chamber",
                role: "Sentinel",
                accent: "#d8b45a"
            },
            clove: {
                name: "Clove",
                role: "Controller",
                accent: "#ff7ad9"
            },
            cypher: {
                name: "Cypher",
                role: "Sentinel",
                accent: "#d9d4c7"
            },
            deadlock: {
                name: "Deadlock",
                role: "Sentinel",
                accent: "#c8d3dc"
            },
            fade: {
                name: "Fade",
                role: "Initiator",
                accent: "#8a6bbf"
            },
            gekko: {
                name: "Gekko",
                role: "Initiator",
                accent: "#b6f23a"
            },
            harbor: {
                name: "Harbor",
                role: "Controller",
                accent: "#1fb5b5"
            },
            iso: {
                name: "Iso",
                role: "Duelist",
                accent: "#8a5cff"
            },
            jett: {
                name: "Jett",
                role: "Duelist",
                accent: "#9fd8e8"
            },
            kayo: {
                name: "KAY/O",
                role: "Initiator",
                accent: "#7fd3ff"
            },
            killjoy: {
                name: "Killjoy",
                role: "Sentinel",
                accent: "#f5d000"
            },
            neon: {
                name: "Neon",
                role: "Duelist",
                accent: "#22c8ff"
            },
            omen: {
                name: "Omen",
                role: "Controller",
                accent: "#5b5fd6"
            },
            phoenix: {
                name: "Phoenix",
                role: "Duelist",
                accent: "#ff8a3d"
            },
            raze: {
                name: "Raze",
                role: "Duelist",
                accent: "#ff6a2b"
            },
            reyna: {
                name: "Reyna",
                role: "Duelist",
                accent: "#b44dff"
            },
            sage: {
                name: "Sage",
                role: "Sentinel",
                accent: "#3fe0c5"
            },
            skye: {
                name: "Skye",
                role: "Initiator",
                accent: "#6fd36f"
            },
            sova: {
                name: "Sova",
                role: "Initiator",
                accent: "#4a8dff"
            },
            tejo: {
                name: "Tejo",
                role: "Initiator",
                accent: "#e0a040"
            },
            viper: {
                name: "Viper",
                role: "Controller",
                accent: "#3ddc84"
            },
            vyse: {
                name: "Vyse",
                role: "Sentinel",
                accent: "#9a9aff"
            },
            waylay: {
                name: "Waylay",
                role: "Duelist",
                accent: "#ff9ad5"
            },
            yoru: {
                name: "Yoru",
                role: "Duelist",
                accent: "#2b6cff"
            }
        })

    readonly property list<string> agentIds: Object.keys(agents).sort()

    // Config values (see valorant.json)
    readonly property bool enabled: cfg.enabled ?? true
    readonly property bool overrideScheme: cfg.overrideScheme ?? true
    readonly property bool active: enabled && overrideScheme
    readonly property string agent: agents.hasOwnProperty(cfg.agent) ? cfg.agent : "valorant"
    readonly property var agentInfo: agents[agent]
    // Shown on the lock screen, dashboard, welcome banner, login screen and boot splash
    readonly property string playerName: (cfg.player?.name ?? "").trim() || SysInfo.realName || SysInfo.user
    readonly property string playerTitle: (cfg.player?.title ?? "").trim() || qsTr("Agent")
    readonly property bool welcomeBanner: cfg.player?.welcome ?? true
    readonly property bool light: (cfg.mode ?? "dark") === "light"
    readonly property color accent: validColour(cfg.accent) ? cfg.accent : agentInfo.accent
    readonly property var paletteCfg: cfg.palette ?? ({})

    readonly property int chamfer: Math.max(0, cfg.shape?.chamfer ?? 10)
    readonly property int chamferSmall: Math.max(1, Math.round(chamfer / 2))
    // Bevel the SDF-drawn panels (dashboard, launcher, sidebar, popouts, settings)
    readonly property bool chamferPanels: enabled && chamfer > 0
    readonly property bool cornerBrackets: cfg.shape?.cornerBrackets ?? true
    readonly property bool accentBar: cfg.shape?.accentBar ?? true
    readonly property int borderWidth: Math.max(0, cfg.shape?.borderWidth ?? 1)

    // Regenerate terminal/Hyprland/GTK/Qt/cursor colours with valo-sync whenever the scheme changes
    readonly property bool syncDotfiles: cfg.syncDotfiles ?? true
    // Switch to the agent's bundled wallpaper on lock-in
    readonly property bool agentWallpapers: cfg.agentWallpapers ?? true
    // Agent portraits over the wallpaper, once `valo-agent-art` has downloaded them
    readonly property bool agentArt: cfg.agentArt ?? true
    readonly property string agentArtDir: `${Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`}/valo-skin/agent-art`
    readonly property bool soundsEnabled: enabled && (cfg.sounds?.enabled ?? true)
    readonly property real soundVolume: Math.max(0, Math.min(1, cfg.sounds?.volume ?? 0.6))
    property var lastPlayed: ({})
    // Agent quick-switch ring visibility (modules/AgentRadialWindow.qml)
    property bool radialOpen

    readonly property real fxIntensity: Math.max(0, Math.min(2, cfg.fx?.intensity ?? 1))
    readonly property bool glitch: (cfg.fx?.glitch ?? true) && fxIntensity > 0
    readonly property bool scanlines: cfg.fx?.scanlines ?? false
    readonly property real scanlineStrength: enabled && scanlines ? 0.12 * Math.min(1.5, fxIntensity) : 0

    readonly property var hud: ({
            roundTimerClock: cfg.hud?.roundTimerClock ?? true,
            abilitySlots: cfg.hud?.abilitySlots ?? true,
            rankWorkspaces: cfg.hud?.rankWorkspaces ?? true,
            killBanners: cfg.hud?.killBanners ?? true,
            chargeOsd: cfg.hud?.chargeOsd ?? true,
            matchStats: cfg.hud?.matchStats ?? true,
            leaveMatch: cfg.hud?.leaveMatch ?? true,
            contractMedia: cfg.hud?.contractMedia ?? true,
            matchHistory: cfg.hud?.matchHistory ?? true,
            spikeLock: cfg.hud?.spikeLock ?? true,
            agentSelectLauncher: cfg.hud?.agentSelectLauncher ?? true,
            loadoutLauncher: cfg.hud?.loadoutLauncher ?? true
        })

    property var cfg: ({})

    readonly property var defaults: ({
            enabled: true,
            agent: "valorant",
            mode: "dark",
            overrideScheme: true,
            syncDotfiles: true,
            agentWallpapers: true,
            agentArt: true,
            accent: "",
            player: {
                name: "",
                title: "",
                welcome: true
            },
            sounds: {
                enabled: true,
                volume: 0.6
            },
            palette: {
                red: "#ff4655",
                navy: "#0f1923",
                white: "#ece8e1",
                teal: "#17d1a6",
                gold: "#e8c06a",
                black: "#0a0e12"
            },
            shape: {
                chamfer: 10,
                cornerBrackets: true,
                accentBar: true,
                borderWidth: 1
            },
            fx: {
                intensity: 1,
                glitch: true,
                scanlines: false
            },
            hud: {
                roundTimerClock: true,
                abilitySlots: true,
                rankWorkspaces: true,
                killBanners: true,
                chargeOsd: true,
                matchStats: true,
                leaveMatch: true,
                contractMedia: true,
                matchHistory: true,
                spikeLock: true,
                agentSelectLauncher: true,
                loadoutLauncher: true
            }
        })

    // Emitted whenever anything that affects the generated colour scheme changes
    signal schemeInputsChanged
    // Emitted when an agent is picked interactively (launcher, settings, IPC), not on config load
    signal agentLockedIn(agentId: string)

    // Whether a redesigned HUD component should replace the stock one
    function hudOn(key: string): bool {
        return enabled && (hud[key] ?? true);
    }

    function validColour(c: var): bool {
        return typeof c === "string" && /^#([0-9a-f]{6}|[0-9a-f]{8})$/i.test(c);
    }

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function onColour(c: color): color {
        const lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
        return lum > 0.45 ? navy : white;
    }

    function hex(c: color): string {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `${h(c.r)}${h(c.g)}${h(c.b)}`;
    }

    // Full Material 3 role map (hex without '#') for Colours.load()
    function scheme(): var {
        const bg = light ? white : navy;
        const fg = light ? navy : white;
        const a = accent;
        // Second accent: Valorant red, unless the agent accent already is red
        const b = Qt.colorEqual(a, red) ? fg : red;
        const step = t => mix(bg, fg, t);

        const c = {
            primary_paletteKeyColor: a,
            secondary_paletteKeyColor: b,
            tertiary_paletteKeyColor: gold,
            neutral_paletteKeyColor: step(0.4),
            neutral_variant_paletteKeyColor: step(0.45),
            background: bg,
            onBackground: fg,
            surface: bg,
            surfaceDim: light ? step(0.08) : mix(bg, black, 0.4),
            surfaceBright: step(0.16),
            surfaceContainerLowest: light ? Qt.lighter(bg, 1.03) : mix(bg, black, 0.5),
            surfaceContainerLow: step(0.04),
            surfaceContainer: step(0.07),
            surfaceContainerHigh: step(0.11),
            surfaceContainerHighest: step(0.15),
            onSurface: fg,
            surfaceVariant: step(0.18),
            onSurfaceVariant: step(0.72),
            inverseSurface: fg,
            inverseOnSurface: bg,
            outline: step(0.42),
            outlineVariant: step(0.22),
            shadow: "#000000",
            scrim: "#000000",
            surfaceTint: a,
            primary: a,
            onPrimary: onColour(a),
            primaryContainer: mix(bg, a, 0.32),
            onPrimaryContainer: light ? mix(a, navy, 0.6) : mix(a, white, 0.7),
            inversePrimary: mix(a, bg, 0.35),
            secondary: b,
            onSecondary: onColour(b),
            secondaryContainer: mix(bg, b, 0.25),
            onSecondaryContainer: light ? mix(b, navy, 0.6) : mix(b, white, 0.75),
            tertiary: gold,
            onTertiary: onColour(gold),
            tertiaryContainer: mix(bg, gold, 0.3),
            onTertiaryContainer: light ? mix(gold, navy, 0.6) : mix(gold, white, 0.7),
            error: light ? "#d6283a" : "#ff5c6c",
            onError: light ? white : "#3a0008",
            errorContainer: mix(bg, red, 0.35),
            onErrorContainer: light ? "#5c0010" : "#ffd9dc",
            success: teal,
            onSuccess: onColour(teal),
            successContainer: mix(bg, teal, 0.3),
            onSuccessContainer: light ? mix(teal, navy, 0.6) : mix(teal, white, 0.7),
            primaryFixed: mix(a, white, 0.6),
            primaryFixedDim: a,
            onPrimaryFixed: mix(a, black, 0.8),
            onPrimaryFixedVariant: mix(a, black, 0.55),
            secondaryFixed: mix(b, white, 0.6),
            secondaryFixedDim: b,
            onSecondaryFixed: mix(b, black, 0.8),
            onSecondaryFixedVariant: mix(b, black, 0.55),
            tertiaryFixed: mix(gold, white, 0.6),
            tertiaryFixedDim: gold,
            onTertiaryFixed: mix(gold, black, 0.8),
            onTertiaryFixedVariant: mix(gold, black, 0.55),
            term0: light ? mix(white, navy, 0.85) : mix(navy, white, 0.12),
            term1: red,
            term2: teal,
            term3: gold,
            term4: "#4a8dff",
            term5: "#b44dff",
            term6: "#3fe0c5",
            term7: light ? navy : white,
            term8: step(0.4),
            term9: Qt.lighter(red, 1.15),
            term10: Qt.lighter(teal, 1.2),
            term11: Qt.lighter(gold, 1.15),
            term12: "#7fb0ff",
            term13: "#cf8aff",
            term14: "#8af0dc",
            term15: "#ffffff"
        };

        const colours = {};
        for (const [k, v] of Object.entries(c))
            colours[k] = hex(Qt.color(v));

        return {
            name: "valorant",
            flavour: agent,
            mode: light ? "light" : "dark",
            variant: "valorant",
            colours
        };
    }

    function merge(base: var, over: var): var {
        const out = Object.assign({}, base);
        for (const [k, v] of Object.entries(over ?? {}))
            out[k] = (v && typeof v === "object" && !Array.isArray(v) && base[k] && typeof base[k] === "object") ? merge(base[k], v) : v;
        return out;
    }

    function save(): void {
        file.setText(JSON.stringify(merge(defaults, cfg), null, 4) + "\n");
    }

    function set(key: string, value: var): void {
        const next = Object.assign({}, cfg);
        const path = key.split(".");
        let o = next;
        for (let i = 0; i < path.length - 1; i++) {
            o[path[i]] = Object.assign({}, o[path[i]] ?? {});
            o = o[path[i]];
        }
        o[path[path.length - 1]] = value;
        cfg = next;
        save();
    }

    function setAgent(id: string): bool {
        id = id.toLowerCase().replace(/[^a-z]/g, "");
        if (!agents.hasOwnProperty(id))
            return false;
        set("agent", id);
        agentLockedIn(id);
        play("lockin");
        if (agentWallpapers)
            Wallpapers.setWallpaper(agentWallpaper(id));
        return true;
    }

    // Bar layouts saved before Valo-skin features existed (an explicit list in shell.json, or a
    // plugin built from older sources) don't mention the new entries, so add them here instead of
    // relying on the plugin defaults. An entry the user lists, even disabled, is left as is.
    function barEntries(list: var): var {
        let out = Array.from(list ?? []).map(e => ({
                    id: e.id,
                    enabled: e.enabled
                }));
        const has = id => out.some(e => e.id === id);
        const insertAfter = (afterId, entry) => {
            const i = out.findIndex(e => e.id === afterId);
            out = i < 0 ? [...out, entry] : [...out.slice(0, i + 1), entry, ...out.slice(i + 1)];
        };
        if (!has("layout"))
            insertAfter("workspaces", {
                id: "layout",
                enabled: true
            });
        if (!has("taskbar")) {
            // The taskbar takes over from the active-window title and the bench
            const i = out.findIndex(e => e.id === "activeWindow");
            const entry = {
                id: "taskbar",
                enabled: true
            };
            if (i >= 0)
                out = [...out.slice(0, i), entry, ...out.slice(i + 1)];
            else
                insertAfter("layout", entry);
            out = out.filter(e => e.id !== "bench");
        }
        return out.filter(e => e.enabled);
    }

    function statusEntries(list: var): var {
        let out = Array.from(list ?? []).map(e => ({
                    id: e.id,
                    enabled: e.enabled
                }));
        const has = id => out.some(e => e.id === id);
        if (!has("privacy")) {
            const i = out.findIndex(e => e.id === "lockStatus");
            out = [...out.slice(0, i + 1),
                {
                    id: "privacy",
                    enabled: true
                },
                ...out.slice(i + 1)];
        }
        for (const id of ["phone", "updates"])
            if (!has(id))
                out.push({
                    id: id,
                    enabled: true
                });
        return out.filter(e => e.enabled);
    }

    function agentArtFile(id: string, kind: string): string {
        return `file://${agentArtDir}/${id}${kind ? `-${kind}` : ""}.png`;
    }

    function agentWallpaper(id: string): string {
        return Quickshell.shellPath(`assets/wallpapers/agents/${id}.webp`);
    }

    // Plays a bundled UI sound (lockin, plant, defuse, fail, banner, tick). Throttled per sound so
    // per-monitor surfaces don't stack copies.
    function play(name: string): void {
        if (!soundsEnabled || soundVolume <= 0)
            return;
        const now = Date.now();
        if (now - (lastPlayed[name] ?? 0) < 400)
            return;
        lastPlayed[name] = now;
        const file = Quickshell.shellPath(`assets/sounds/${name}.wav`);
        const vol = soundVolume.toFixed(2);
        Quickshell.execDetached(["sh", "-c", 'pw-play --volume="$1" "$2" 2>/dev/null || paplay --volume="$(awk "BEGIN{print int($1*65536)}")" "$2" 2>/dev/null || aplay -q "$2"', "valo-sound", vol, file]);
    }

    function cycleAgent(dir: int): void {
        const i = agentIds.indexOf(agent);
        setAgent(agentIds[(i + dir + agentIds.length) % agentIds.length]);
    }

    onCfgChanged: {
        schemeInputsChanged();
        publishTimer.restart();
    }

    // Coalesce rapid changes (e.g. cycling agents) into one publish + sync
    Timer {
        id: publishTimer

        interval: 400
        onTriggered: {
            if (!root.enabled)
                return;
            schemeFile.setText(JSON.stringify(Object.assign(root.scheme(), {
                agentName: root.agentInfo.name,
                role: root.agentInfo.role,
                chamfer: root.chamfer
            }), null, 2) + "\n");
            if (root.syncDotfiles)
                Quickshell.execDetached(["sh", "-c", "PATH=\"$PATH:$HOME/.local/bin\"; command -v valo-sync >/dev/null && exec valo-sync --quiet"]);
        }
    }

    // Last generated scheme for external tools (valo-sync, scripts)
    FileView {
        id: schemeFile

        path: `${Paths.state}/valorant-scheme.json`
        printErrors: false
    }

    FileView {
        id: file

        path: `${Paths.config}/valorant.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.cfg = JSON.parse(text());
            } catch (e) {
                console.warn("valorant.json: invalid JSON, using defaults:", e);
                root.cfg = root.defaults;
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.cfg = root.defaults;
                root.save();
            }
        }
    }

    IpcHandler {
        function agent(id: string): string {
            return root.setAgent(id) ? `Agent locked in: ${root.agentInfo.name}` : `Unknown agent "${id}". Try: ${root.agentIds.join(", ")}`;
        }

        function next(): string {
            root.cycleAgent(1);
            return root.agentInfo.name;
        }

        function prev(): string {
            root.cycleAgent(-1);
            return root.agentInfo.name;
        }

        function current(): string {
            return root.agent;
        }

        function list(): string {
            return root.agentIds.map(id => `${id}\t${root.agents[id].role}\t${root.agents[id].accent}`).join("\n");
        }

        function accent(hex: string): string {
            if (hex === "" || hex === "reset") {
                root.set("accent", "");
                return "Accent reset to agent colour";
            }
            if (!root.validColour(hex))
                return "Expected #rrggbb";
            root.set("accent", hex);
            return `Accent set to ${hex}`;
        }

        function mode(m: string): string {
            if (m !== "dark" && m !== "light")
                return "Expected dark or light";
            root.set("mode", m);
            return `Mode: ${m}`;
        }

        function radial(): void {
            root.radialOpen = !root.radialOpen;
        }

        function sound(name: string): string {
            root.play(name);
            return root.soundsEnabled ? `Playing ${name}` : "Sounds are disabled";
        }

        function toggle(): string {
            root.set("overrideScheme", !root.overrideScheme);
            return root.overrideScheme ? "Valorant palette on" : "Valorant palette off (wallpaper scheme)";
        }

        target: "valorant"
    }
}
