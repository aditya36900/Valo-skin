# Valo-skin dotfiles

Everything outside the shell follows the current agent. When you switch agents (launcher,
settings, `SUPER+ALT+←/→` or IPC), the shell publishes its colour scheme to
`~/.local/state/caelestia/valorant-scheme.json` and runs **`valo-sync`**. That script rewrites
small colour *include* files and reloads what it can. Your own config files are never rewritten.

| App | File valo-sync writes | How it's included | Live reload |
|---|---|---|---|
| Hyprland (Lua) | `~/.config/hypr/valorant-colors.lua` | `valorant.lua` requires it; your `hyprland.lua` gets `require("valorant")` | `hyprctl reload` |
| Hyprland (hyprlang) | `~/.config/hypr/valorant-colors.conf` | `valorant.conf` sources it; `hyprland.conf` gets `source = …/valorant.conf` | `hyprctl reload` |
| kitty | `~/.config/kitty/valorant.conf` | `include valorant.conf` in `kitty.conf` | SIGUSR1 |
| foot | `~/.config/foot/valorant.ini` | `include=…/valorant.ini` in `foot.ini` | SIGUSR1 |
| alacritty | `~/.config/alacritty/valorant.toml` | `[general] import` (created if you have no `alacritty.toml`) | automatic |
| fastfetch | `~/.config/fastfetch/valorant.jsonc` + emblem logo | `config.jsonc` symlink if you have none, else `fastfetch -c valorant` | next run |
| GTK 3 / 4 (libadwaita, adw-gtk3) | `~/.config/gtk-{3,4}.0/valorant.css` | `@import 'valorant.css';` at the top of `gtk.css` | restart the app |
| Qt (qt5ct / qt6ct) | `~/.config/qt{5,6}ct/colors/valorant.conf` | `custom_palette` + `color_scheme_path` in `qt{5,6}ct.conf` | restart the app |
| Cursor | `~/.local/share/icons/Valo-Crosshair` (rebuilt in your accent) | `XCURSOR_THEME`, `~/.icons/default`, gsettings | new windows |

Every line the installer adds ends with a `valo-skin` tag, so `./install.sh --uninstall` can find
and remove it. It backs up every file it touches to `~/.local/share/valo-skin/backups/<date>/`.
If the installer had to create `qt5ct.conf`/`qt6ct.conf`, uninstall leaves that file behind with
only `custom_palette=false` (the default).

## Hyprland look

`dots/hypr/valorant.lua` (and the equivalent `valorant.conf`) sets:

- 2 px borders with a rotating agent-accent → red gradient; inactive borders in the outline colour
- `rounding = 0`, gaps 4/8 to match the shell's screen frame, hard 4 px offset shadows, blur on
- "valoSnap" animations: quick slides with a slight overshoot, vertical workspace slides
- the Valo-Crosshair cursor and the `qt6ct` platform theme via env
- extra binds:

| Bind | Action |
|---|---|
| `SUPER+ALT+→` / `←` | Next / previous agent |
| `SUPER+ALT+V` | Valorant palette ↔ wallpaper scheme |
| `SUPER+ALT+L` / `D` | Light / dark mode |
| `SUPER+ALT+S` | Re-run valo-sync |

It's loaded *after* your own settings, so it wins on conflicts. To change something, put your
override after the `require("valorant")` / `source` line.

## valo-sync

```sh
valo-sync                    # apply the scheme the shell last published
valo-sync --dry-run          # show what would change
valo-sync --only kitty,gtk   # limit targets
valo-sync --accent '#00ffcc' # custom accent without the shell (add --light for light mode)
valo-sync --print            # dump the scheme JSON
```

It only writes files whose content changed, and only reloads apps when something did. To stop
the shell running it automatically, set `"syncDotfiles": false` in `valorant.json`.

The fallback scheme (used before the shell has published one, or with `--accent`) is a Python
port of the shell's generator. It produces the exact same hex values.

## Cursor theme

`valo-cursors` draws the Valo-Crosshair XCursor theme in pure Python at 24/32/48/64 px: angular
arrows with an accent stripe, an accent pointer, a Valorant-style crosshair, an I-beam, a spike
"busy" diamond, and chamfered resize/move glyphs. Run `valo-cursors --accent '#rrggbb'` to tint it
yourself. Anything it doesn't draw falls back to Adwaita.

<img src="previews/cursors.png" width="700">
