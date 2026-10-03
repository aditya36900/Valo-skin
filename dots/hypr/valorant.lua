-- Valo-skin: Valorant look and feel for Hyprland (Lua config).
-- Load it from your hyprland.lua with:  require("valorant")
-- Colours come from valorant-colors.lua, which valo-sync regenerates when you switch agents.
-- Override anything after the require() line in your own config.

local ok, c = pcall(require, "valorant-colors")
if not ok then
    c = {
        accent = "ff4655",
        active_border = { colors = { "rgba(ff4655ff)", "rgba(ece8e1ff)" }, angle = 45 },
        inactive_border = "rgba(2f3a44cc)",
        group_active = "rgba(ff4655ff)",
        group_inactive = "rgba(26313bff)",
        shadow = "rgba(0f1923cc)",
    }
end

----------------
---- LOOK ----
----------------

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8, -- matches the shell's screen frame
        border_size = 2,
        col = {
            active_border = c.active_border,
            inactive_border = c.inactive_border,
        },
        resize_on_border = true,
        layout = "dwindle", -- SUPER+ALT+T cycles dwindle / master / scrolling
    },

    -- Auto-tiling: new windows split the focused one along its longer side and keep the split
    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

    master = {
        new_status = "master",
        mfact = 0.55,
    },

    decoration = {
        rounding = 0, -- HUD corners are sharp
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        dim_inactive = false,

        shadow = {
            enabled = true,
            range = 10,
            render_power = 4,
            offset = "4 4", -- hard offset shadow, like HUD panels
            color = c.shadow,
        },

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            vibrancy = 0.2,
        },
    },

    group = {
        col = {
            border_active = c.group_active,
            border_inactive = c.group_inactive,
        },
        groupbar = {
            font_family = "Oswald",
            font_size = 11,
            gradients = false,
            col = {
                active = c.group_active,
                inactive = c.group_inactive,
            },
        },
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = 0xff0f1923,
    },

    cursor = {
        no_hardware_cursors = false,
    },
})

---------------------
---- ANIMATIONS ----
---------------------
-- Snappy and decisive: quick slides with a slight overshoot, like ability casts.

hl.config({ animations = { enabled = true } })

hl.curve("valoSnap", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("valoOut", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("valoLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "valoSnap" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.2, bezier = "valoSnap", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.2, bezier = "valoOut", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "valoSnap" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "valoLinear" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "valoLinear", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "valoSnap" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "valoSnap", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "valoSnap", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "valoSnap", style = "slidefadevert 20%" })

------------------
---- CURSOR ----
------------------

hl.env("XCURSOR_THEME", "Valo-Crosshair")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Valo-Crosshair")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-------------------
---- RULES ----
-------------------

-- The shell's drawers already have their own chamfered frame
hl.layer_rule({ name = "valo-drawers-noanim", match = { namespace = "caelestia-drawers" }, no_anim = true })

-- Multitasking like Plasma: windows that ask for attention (dialogs, links opened from other apps)
-- get focus, modal dialogs float centred, and password prompts always take the keyboard
hl.config({ misc = { focus_on_activate = true } })
hl.window_rule({ name = "valo-modal", match = { modal = true }, float = true, center = true })
hl.window_rule({
    name = "valo-polkit",
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1|polkit-kde-authentication-agent-1|hyprpolkitagent|lxqt-policykit-agent|polkit-gnome-authentication-agent-1|gcr-prompter|org.kde.ksecretd|pinentry-qt|pinentry-gtk.*)$" },
    float = true,
    center = true,
    pin = true,
    stay_focused = true,
})

-- Floating pickers and dialogs get the accent border too, centred
hl.window_rule({
    name = "valo-dialogs",
    match = { class = "^(xdg-desktop-portal-gtk|org.gnome.FileRoller|pavucontrol|org.pulseaudio.pavucontrol)$" },
    float = true,
    center = true,
})

-----------------------
---- KEYBINDINGS ----
-----------------------
-- Valo-skin extras only; your own binds stay in hyprland.lua.

local valo = "qs -c caelestia ipc call valorant "

hl.bind("SUPER + ALT + right", hl.dsp.exec_cmd(valo .. "next")) -- next agent
hl.bind("SUPER + ALT + left", hl.dsp.exec_cmd(valo .. "prev")) -- previous agent
hl.bind("SUPER + ALT + A", hl.dsp.exec_cmd(valo .. "radial")) -- agent quick-switch ring
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd(valo .. "toggle")) -- Valorant palette <-> wallpaper scheme
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd(valo .. "mode light"))
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd(valo .. "mode dark"))
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd("valo-sync")) -- force-resync dotfile colours
hl.bind("SUPER + ALT + T", hl.dsp.exec_cmd("qs -c caelestia ipc call layout next")) -- cycle tiling layout
-- Hyprland has no minimize: park the window on the bench (special:minimized), call it back
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("qs -c caelestia ipc call bench minimize"))
hl.bind("SUPER + ALT + SHIFT + M", hl.dsp.exec_cmd("qs -c caelestia ipc call bench restore"))
hl.bind("ALT + TAB", hl.dsp.exec_cmd("qs -c caelestia ipc call taskbar next")) -- task switcher
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("qs -c caelestia ipc call taskbar prev"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("qs -c caelestia ipc call stash open")) -- clipboard history
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("qs -c caelestia ipc call nightops toggle")) -- blue-light filter
hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("qs -c caelestia ipc call uplink ring")) -- find my phone
