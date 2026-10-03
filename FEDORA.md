# Fedora 44 support

This repository is the Caelestia shell, not the complete Caelestia Hyprland
dotfiles repository. Fedora support is provided by
`scripts/install-fedora.sh`; it builds the shell with Fedora's system Qt and
Quickshell packages and installs user-owned files under `~/.local` and
`~/.config`.

## Prerequisites

Fedora 44 includes Quickshell and the build/runtime libraries used by the
plugin. Hyprland is not consistently available from Fedora's base repositories
for Fedora 44, so enable the third-party COPR before installing:

```sh
sudo dnf install dnf-plugins-core
sudo dnf copr enable ashbuk/Hyprland-Fedora
```

Review that COPR's packages match your graphics stack before enabling it. The
installer can perform both steps with `--enable-copr`.

The separate `caelestia-cli` is optional. Install it from its upstream project
if you want wallpaper/IPC commands such as `caelestia shell`; the graphical
shell itself does not require the CLI.

## Install

From the repository root:

```sh
chmod +x scripts/install-fedora.sh
scripts/install-fedora.sh --enable-copr
```

To let Fedora's user systemd instance start the shell with the graphical
session, add `--enable-systemd`. Otherwise add this to Hyprland's Lua config:

```lua
hl.exec_cmd("caelestia-shell")
```

The launcher sets `CAELESTIA_LIB_DIR` and `QML2_IMPORT_PATH`, which are needed
for a user-local install of the C++ plugin. No `/usr/bin`, `/usr/lib`,
`pacman`, AUR helper, Nix, or Debian path is assumed.

## Fedora package map

| Upstream/Arch name | Fedora name |
| --- | --- |
| `quickshell-git` | `quickshell` |
| `qt6-declarative` | `qt6-qtdeclarative-devel` |
| `qt6-shadertools` | `qt6-qtshadertools-devel` |
| `libpipewire` | `pipewire-devel` |
| `libcava` | bundled `cavacore` fallback; Fedora's runtime package is `cava` |
| `lm-sensors` | `lm_sensors-devel` |
| `caskaydia-cove-nerd` | `cascadia-code-nf-fonts` |
| `ninja` | `ninja-build` |

Runtime utilities such as `brightnessctl`, `ddcutil`, `swappy`,
`wl-clipboard`, `playerctl`, `grim`, `slurp`, and `mako` retain the same
Fedora package names. `wpctl` is supplied by `pipewire-utils`.

Fedora does not provide a stable `material-symbols` package name across all
releases. Install the Material Symbols font from Google (or copy the font
files into `~/.local/share/fonts`) and run `fc-cache -f` if icons render as
missing glyphs. `google-rubik-fonts` and `cascadia-code-nf-fonts` are installed
by the script.

The upstream Arch and Nix files remain available for those platforms; they are
not used by the Fedora installer or build.
