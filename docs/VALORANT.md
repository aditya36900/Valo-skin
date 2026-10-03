# valorant.json reference

Location: `~/.config/caelestia/valorant.json` (or `$XDG_CONFIG_HOME/caelestia/valorant.json`).

Valo-skin writes this file with every option filled in on first launch. Edits apply as soon as you
save. Any key you leave out falls back to its default, and invalid JSON is ignored with a warning in
the shell log, so the defaults are used until you fix it.

## Top level

| Key | Type | Default | Description |
|---|---|---|---|
| `enabled` | bool | `true` | Master switch for Valorant styling (palette override and chamfered panels). |
| `agent` | string | `"valorant"` | Agent theme id. See [agents](#agents). Unknown ids fall back to `valorant`. |
| `mode` | `"dark"` \| `"light"` | `"dark"` | Navy background with off-white text, or the reverse. |
| `overrideScheme` | bool | `true` | Use the generated Valorant palette instead of the wallpaper/CLI scheme (`~/.local/state/caelestia/scheme.json`). |
| `accent` | `"#rrggbb"` \| `""` | `""` | Custom primary accent. Empty uses the agent's colour. |

## `palette`

The base colours every scheme is generated from. Change these to make your own variation.

| Key | Default | Used for |
|---|---|---|
| `red` | `#ff4655` | Secondary accent (primary for the `valorant` agent), terminal red |
| `navy` | `#0f1923` | Dark background, light-mode text |
| `white` | `#ece8e1` | Light background, dark-mode text |
| `teal` | `#17d1a6` | Success colours, terminal green |
| `gold` | `#e8c06a` | Tertiary colours, terminal yellow |
| `black` | `#0a0e12` | Deepest surfaces, text on bright accents |

How the scheme is built: surfaces step from the background towards the text colour in small
increments. Primary is the agent accent. Secondary is Valorant red, or the text colour when the
accent is already red. Containers are the accent mixed into the background. "On" colours are picked
by luminance for contrast.

## `shape`

| Key | Type | Default | Description |
|---|---|---|---|
| `chamfer` | int (px) | `10` | Bevel size for panels (dashboard, launcher, sidebar, popouts, settings). Small blobs use half. `0` turns chamfer mode off, so panels use `appearance.rounding` instead. |
| `cornerBrackets` | bool | `true` | HUD corner brackets around the spike-lock defuse bar (more surfaces in Phase 3). |
| `accentBar` | bool | `true` | Urgency-coloured stripe on kill-banner notifications. |
| `borderWidth` | int (px) | `1` | Reserved for HUD frame outlines *(Phase 3)*. |

The screen-frame bevel is `border.rounding` in `shell.json` (default `18`). How sharp the bevels
are where panels meet the frame is `border.smoothing` (default `12`; lower is tighter).

## `fx`

| Key | Type | Default | Description |
|---|---|---|---|
| `intensity` | 0–2 | `1` | HUD effect strength: spike pulse, failed-defuse shake and kill-banner flash (flash brightness scales up to 1). `0` turns them all off. |
| `glitch` | bool | `true` | Reserved: glitch transition on agent switch *(Phase 3)*. |
| `scanlines` | bool | `false` | Reserved: scanline overlay on panels *(Phase 3)*. |

## `hud`

Each of these turns one redesigned component on or off. `false` keeps the stock Caelestia version.
They all also require `enabled: true`.

| Key | Component |
|---|---|
| `roundTimerClock` | Bar clock as the round timer: stacked HH/MM with a bar that drains each minute and turns red for the last 10 seconds |
| `abilitySlots` | Bar status icons in chamfered ability slots with keybind hints; audio, mic, network and battery show 4-pip charge levels |
| `rankWorkspaces` | Bar workspaces as diamond pips (faint = empty, filled = occupied, large on a chamfered highlight = active) |
| `killBanners` | Notification popups as kill-feed banners (accent: red = critical, agent colour = normal, grey = low) |
| `chargeOsd` | Volume/mic/brightness sliders as ability charge meters; turn gold at 100% |
| `spikeLock` | Lock screen password input as a spike defuse bar |
| `agentSelectLauncher` | Agent-select grid in the launcher *(Phase 3)* |

## Agents

| id | Role | Accent |
|---|---|---|
| `valorant` | Default | `#ff4655` |
| `astra` | Controller | `#a35cff` |
| `breach` | Initiator | `#ff7b2e` |
| `brimstone` | Controller | `#ff9f43` |
| `chamber` | Sentinel | `#d8b45a` |
| `clove` | Controller | `#ff7ad9` |
| `cypher` | Sentinel | `#d9d4c7` |
| `deadlock` | Sentinel | `#c8d3dc` |
| `fade` | Initiator | `#8a6bbf` |
| `gekko` | Initiator | `#b6f23a` |
| `harbor` | Controller | `#1fb5b5` |
| `iso` | Duelist | `#8a5cff` |
| `jett` | Duelist | `#9fd8e8` |
| `kayo` | Initiator | `#7fd3ff` |
| `killjoy` | Sentinel | `#f5d000` |
| `neon` | Duelist | `#22c8ff` |
| `omen` | Controller | `#5b5fd6` |
| `phoenix` | Duelist | `#ff8a3d` |
| `raze` | Duelist | `#ff6a2b` |
| `reyna` | Duelist | `#b44dff` |
| `sage` | Sentinel | `#3fe0c5` |
| `skye` | Initiator | `#6fd36f` |
| `sova` | Initiator | `#4a8dff` |
| `tejo` | Initiator | `#e0a040` |
| `viper` | Controller | `#3ddc84` |
| `vyse` | Sentinel | `#9a9aff` |
| `waylay` | Duelist | `#ff9ad5` |
| `yoru` | Duelist | `#2b6cff` |

Accents are hand-picked approximations, not official values.

## IPC

All commands are available as `qs -c caelestia ipc call valorant <cmd> [arg]` or
`caelestia shell valorant <cmd> [arg]`.

| Command | Description |
|---|---|
| `agent <id>` | Lock in an agent theme |
| `next` / `prev` | Cycle agents alphabetically |
| `current` | Print the current agent id |
| `list` | Print `id  role  accent` for every agent |
| `accent <#rrggbb\|reset>` | Set or clear a custom accent |
| `mode <dark\|light>` | Switch mode |
| `toggle` | Switch between the Valorant palette and the wallpaper scheme |

Every IPC change is saved back to `valorant.json`.

Example Hyprland binds:

```ini
bind = SUPER ALT, right, exec, qs -c caelestia ipc call valorant next
bind = SUPER ALT, left,  exec, qs -c caelestia ipc call valorant prev
```
