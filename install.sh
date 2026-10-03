#!/usr/bin/env bash
# Valo-skin installer: shell + Valorant dotfiles for Arch and Fedora.
#
# Safe to re-run. Every file it changes is backed up first, and it never rewrites your own
# configs: it only adds one tagged include line per app ("# valo-skin"), which --uninstall removes.
set -Eeuo pipefail

src="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly src
readonly config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly bin_dir="${HOME}/.local/bin"
readonly qs_dir="${config_home}/quickshell/caelestia"
backup_dir="${data_home}/valo-skin/backups/$(date +%Y%m%d-%H%M%S)"
readonly backup_dir
readonly tag="valo-skin"

do_deps=1
do_shell=1
do_dots=1
do_sddm=0
do_firefox=0
do_dev=0
do_plymouth=0
do_agent_art=0
hypr_mode=auto
assume_yes=0
dry_run=0
uninstall=0
player_name=""

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Installs the Valo-skin shell and Valorant-themed dotfiles.

  --no-deps          Don't install packages
  --no-shell         Don't build/install the shell
  --no-dots          Don't install Hyprland/terminal/GTK/Qt/cursor theming
  --sddm             Also install the Valo-skin SDDM login theme and make SDDM your login
                     manager (root; your previous one is restored by --uninstall)
  --firefox          Also theme Firefox/LibreWolf profiles with userChrome.css
  --dev              Also run the coding-tools installer (scripts/dev-tools.sh; --help there for modules)
  --plymouth         Also install and enable the Valo-skin Plymouth boot splash (root)
  --agent-art        Download agent portraits for the wallpapers and login screen (valo-agent-art;
                     Riot artwork fetched from valorant-api.com for personal use, not shipped here)
  --hypr=MODE        lua | conf | auto (default: detect hyprland.lua vs hyprland.conf)
  --player=NAME      Your name for the lock screen, dashboard, welcome banner, login screen
                     and boot splash (saved to valorant.json; default: your account's full name)
  -y, --yes          Don't ask for confirmation
  --dry-run          Print what would happen without changing anything
  --uninstall        Remove Valo-skin include lines, generated files and the cursor theme
  -h, --help         Show this help

Supported: Arch (and derivatives) and Fedora 44. Other distros: use --no-deps.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --no-deps) do_deps=0 ;;
        --no-shell) do_shell=0 ;;
        --no-dots) do_dots=0 ;;
        --sddm) do_sddm=1 ;;
        --firefox) do_firefox=1 ;;
        --dev) do_dev=1 ;;
        --plymouth) do_plymouth=1 ;;
        --agent-art) do_agent_art=1 ;;
        --hypr=lua|--hypr=conf|--hypr=auto) hypr_mode="${arg#--hypr=}" ;;
        --player=*) player_name="${arg#--player=}" ;;
        -y|--yes) assume_yes=1 ;;
        --dry-run) dry_run=1 ;;
        --uninstall) uninstall=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: ${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

# ------------------------------------------------------------------ helpers

red=$'\e[38;2;255;70;85m'; dim=$'\e[2m'; bold=$'\e[1m'; off=$'\e[0m'
say() { printf '%s▌%s %s\n' "$red" "$off" "$*"; }
step() { printf '\n%s%s// %s%s\n' "$bold" "$red" "$*" "$off"; }
note() { printf '  %s%s%s\n' "$dim" "$*" "$off"; }

run() {
    if (( dry_run )); then
        printf '  %s[dry-run]%s %s\n' "$dim" "$off" "$*"
    else
        "$@"
    fi
}

backup() {
    local f="$1"
    [[ -e "$f" || -L "$f" ]] || return 0
    local dest="${backup_dir}${f#"${HOME}"}"
    run mkdir -p "$(dirname -- "$dest")"
    run cp -a -- "$f" "$dest"
}

# Sets key=value in a KDE-style INI file (konsolerc), via kwriteconfig when available.
# Usage: kde_set FILE GROUP KEY VALUE   (empty VALUE deletes the key)
kde_set() {
    local file="$1" group="$2" key="$3" value="$4" kw
    kw="$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)"
    if [[ -n "$kw" ]]; then
        if [[ -n "$value" ]]; then
            run "$kw" --file "$file" --group "$group" --key "$key" "$value"
        else
            run "$kw" --file "$file" --group "$group" --key "$key" --delete
        fi
        return
    fi
    (( dry_run )) && { printf '  %s[dry-run]%s %s [%s] %s=%s\n' "$dim" "$off" "$file" "$group" "$key" "$value"; return; }
    python3 - "$file" "$group" "$key" "$value" <<'PY'
import sys
from pathlib import Path
path, group, key, value = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
lines = path.read_text().splitlines() if path.exists() else []
out, in_group, done, seen_group = [], False, False, False
for line in lines:
    s = line.strip()
    if s.startswith("[") and s.endswith("]"):
        if in_group and not done and value:
            out.append(f"{key}={value}"); done = True
        in_group = s[1:-1] == group
        seen_group |= in_group
    elif in_group and s.split("=", 1)[0] == key:
        if value and not done:
            out.append(f"{key}={value}"); done = True
        continue
    out.append(line)
if value and not done:
    if not (in_group and seen_group):
        out += ["", f"[{group}]"] if out else [f"[{group}]"]
    out.append(f"{key}={value}")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text("\n".join(out) + "\n")
PY
}


# Append (or with ADD_LINE_PREPEND=1, prepend) "<line> <comment> valo-skin<suffix>" to a file,
# unless an equivalent tagged line exists
add_line() {
    local file="$1" line="$2" comment="${3:-#}" suffix="${4:-}"
    if [[ -f "$file" ]] && grep -qF -- "$tag" "$file" && grep -qF -- "$line" "$file"; then
        note "already set up: ${file/#${HOME}/\~}"
        return 0
    fi
    backup "$file"
    run mkdir -p "$(dirname -- "$file")"
    if (( dry_run )); then
        note "would add to ${file}: ${line}"
    else
        local entry
        entry="$(printf '%s %s %s%s' "$line" "$comment" "$tag" "$suffix")"
        if [[ "${ADD_LINE_PREPEND:-0}" == 1 && -s "$file" ]]; then
            printf '%s\n%s\n' "$entry" "$(cat -- "$file")" > "${file}.valo-tmp" && mv -- "${file}.valo-tmp" "$file"
        else
            printf '\n%s\n' "$entry" >> "$file"
        fi
    fi
    say "linked ${file/#${HOME}/\~}"
}

remove_tagged() {
    local file="$1"
    [[ -f "$file" ]] && grep -qF -- "$tag" "$file" || return 0
    backup "$file"
    run sed -i -E "/ ${tag}( \\*\/)?\$/d" "$file"
    if (( ! dry_run )) && ! grep -q '[^[:space:]]' "$file"; then
        rm -f -- "$file" # only ever held our line
    fi
    say "cleaned ${file/#${HOME}/\~}"
}

# Set key=value inside an INI section (creates section/key if missing)
ini_set() {
    local file="$1" section="$2" key="$3" value="$4"
    run python3 - "$file" "$section" "$key" "$value" <<'PY'
import sys, re
path, section, key, value = sys.argv[1:]
try:
    lines = open(path).read().splitlines()
except FileNotFoundError:
    lines = []
out, in_sec, done, seen = [], False, False, False
for ln in lines:
    m = re.match(r"\s*\[(.+)\]\s*$", ln)
    if m:
        if in_sec and not done:
            # Insert before the blank lines that separate sections
            i = len(out)
            while i > 0 and not out[i - 1].strip():
                i -= 1
            out.insert(i, f"{key}={value}"); done = True
        in_sec = m.group(1) == section
        seen = seen or in_sec
    elif in_sec and re.match(rf"\s*{re.escape(key)}\s*=", ln):
        ln = f"{key}={value}"; done = True
    out.append(ln)
if not seen:
    out += ["", f"[{section}]"]
    in_sec = True
if not done:
    out.append(f"{key}={value}")
open(path, "w").write("\n".join(out).lstrip("\n") + "\n")
PY
}

confirm() {
    (( assume_yes || dry_run )) && return 0
    read -r -p "$1 [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

if [[ "${EUID}" -eq 0 && -z "${VALO_ALLOW_ROOT:-}" ]]; then
    echo "Run as your normal user; the script uses sudo where needed." >&2
    exit 1
fi

distro=unknown
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == arch || " ${ID_LIKE:-} " == *" arch "* ]]; then
        distro=arch
    elif [[ "${ID:-}" == fedora ]]; then
        distro=fedora
    fi
fi

printf '%s%s' "$red" "$bold"
cat <<'EOF'
 ╱━━━━               ━━━━╲
┃     V A L O - S K I N     ┃
 ╲━━━━               ━━━━╱
EOF
printf '%s' "$off"

# ------------------------------------------------------------------ uninstall

if (( uninstall )); then
    step "Uninstalling Valo-skin theming"
    for f in "${config_home}/hypr/hyprland.lua" "${config_home}/hypr/hyprland.conf" \
             "${config_home}/kitty/kitty.conf" "${config_home}/foot/foot.ini" \
             "${config_home}/gtk-3.0/gtk.css" "${config_home}/gtk-4.0/gtk.css"; do
        remove_tagged "$f"
    done
    for prof in "${HOME}"/.mozilla/firefox/*/ "${HOME}"/.librewolf/*/ "${HOME}"/.zen/*/; do
        [[ -e "${prof}chrome/.valo-skin" ]] || continue
        remove_tagged "${prof}chrome/userChrome.css"
        remove_tagged "${prof}user.js"
        run rm -f -- "${prof}chrome/.valo-skin" "${prof}chrome/valorant.css" "${prof}chrome/valorant-colors.css"
    done
    for d in .vscode .vscode-oss .vscode-insiders .cursor .windsurf; do
        run rm -rf -- "${HOME}/${d}/extensions/valo-skin.valorant-theme-1.0.0"
    done
    run rm -rf -- "${config_home}/spicetify/Themes/Valorant"
    for f in btop/themes/valorant.theme nvim/colors/valorant.lua vesktop/themes/valorant.theme.css \
             Vencord/themes/valorant.theme.css equibop/themes/valorant.theme.css; do
        [[ -e "${config_home}/${f}" ]] && run rm -f -- "${config_home}/${f}"
    done
    for f in hypr/valorant.lua hypr/valorant.conf hypr/valorant-colors.lua hypr/valorant-colors.conf \
             kitty/valorant.conf foot/valorant.ini alacritty/valorant.toml fastfetch/valorant.jsonc \
             gtk-3.0/valorant.css gtk-4.0/valorant.css qt5ct/colors/valorant.conf qt6ct/colors/valorant.conf; do
        [[ -e "${config_home}/${f}" ]] && run rm -f -- "${config_home}/${f}"
    done
    if [[ "$(readlink "${config_home}/fastfetch/config.jsonc" 2>/dev/null)" == valorant.jsonc ]]; then
        run rm -f -- "${config_home}/fastfetch/config.jsonc"
    fi
    if [[ -f "${config_home}/alacritty/alacritty.toml" ]] && [[ "$(grep -vc "$tag" "${config_home}/alacritty/alacritty.toml")" == 1 ]]; then
        run rm -f -- "${config_home}/alacritty/alacritty.toml" # only contained our import
    fi
    if grep -qx "Inherits=Valo-Crosshair" "${HOME}/.icons/default/index.theme" 2>/dev/null; then
        backup "${HOME}/.icons/default/index.theme"
        run rm -f -- "${HOME}/.icons/default/index.theme"
    fi
    run rm -rf -- "${data_home}/icons/Valo-Crosshair"
    for ct in qt5ct qt6ct; do
        conf="${config_home}/${ct}/${ct}.conf"
        if grep -q "colors/valorant.conf" "$conf" 2>/dev/null; then
            backup "$conf"
            run sed -i -e '/^color_scheme_path=.*colors\/valorant\.conf$/d' -e 's/^custom_palette=true$/custom_palette=false/' "$conf"
            say "cleaned ${conf/#${HOME}/\~}"
        fi
    done
    if grep -q '^color_theme = "valorant"' "${config_home}/btop/btop.conf" 2>/dev/null; then
        backup "${config_home}/btop/btop.conf"
        run sed -i 's|^color_theme = "valorant"|color_theme = "Default"|' "${config_home}/btop/btop.conf"
    fi
    if grep -q "^DefaultProfile=Valorant.profile" "${config_home}/konsolerc" 2>/dev/null; then
        backup "${config_home}/konsolerc"
        kde_set "${config_home}/konsolerc" "Desktop Entry" DefaultProfile ""
        kde_set "${config_home}/konsolerc" TabBar TabBarUseUserStyleSheet ""
        kde_set "${config_home}/konsolerc" TabBar TabBarUserStyleSheetFile ""
        say "Konsole profile reset"
    fi
    run rm -f -- "${data_home}/konsole/Valorant.colorscheme" "${data_home}/konsole/Valorant.profile" "${data_home}/valo-skin/konsole-tabs.css"
    for d in Code "Code - OSS" VSCodium Cursor; do
        settings="${config_home}/${d}/User/settings.json"
        grep -q "Valorant (Valo-skin)" "$settings" 2>/dev/null || continue
        backup "$settings"
        (( dry_run )) || python3 - "$settings" <<'PY' || true
import json, sys
path = sys.argv[1]
data = json.load(open(path))
if data.get("workbench.colorTheme") == "Valorant (Valo-skin)":
    del data["workbench.colorTheme"]
json.dump(data, open(path, "w"), indent=4)
open(path, "a").write("\n")
PY
        say "cleaned ${d} settings"
    done
    for d in alacritty fastfetch foot gtk-3.0 gtk-4.0 qt5ct/colors qt6ct/colors btop/themes nvim/colors nvim kitty hypr \
             vesktop/themes Vencord/themes; do
        [[ -d "${config_home}/${d}" ]] && run rmdir --ignore-fail-on-non-empty -- "${config_home}/${d}"
    done
    for prof in "${HOME}"/.mozilla/firefox/*/ "${HOME}"/.librewolf/*/ "${HOME}"/.zen/*/; do
        [[ -d "${prof}chrome" ]] && run rmdir --ignore-fail-on-non-empty -- "${prof}chrome"
    done
    if [[ -f /etc/sddm.conf.d/10-valo-skin.conf ]]; then
        run sudo rm -f /etc/sddm.conf.d/10-valo-skin.conf
        run sudo rm -rf /usr/share/sddm/themes/valo-skin
        say "removed SDDM theme"
    fi
    if [[ -f "${data_home}/valo-skin/dm-previous" ]]; then
        prev_dm="$(cat "${data_home}/valo-skin/dm-previous")"
        run sudo systemctl disable sddm.service
        run sudo systemctl enable -f "${prev_dm}.service"
        run rm -f -- "${data_home}/valo-skin/dm-previous"
        say "Login manager restored to ${prev_dm} (after a reboot)"
    fi
    if [[ -d /usr/share/plymouth/themes/valo-skin ]]; then
        prev="$(cat "${data_home}/valo-skin/plymouth-previous" 2>/dev/null || echo bgrt)"
        command -v plymouth-set-default-theme >/dev/null && run sudo plymouth-set-default-theme "$prev"
        run sudo rm -rf /usr/share/plymouth/themes/valo-skin
        say "Plymouth theme reset to ${prev} (rebuild your initramfs to apply)"
    fi
    run rm -f -- "${bin_dir}/valo-sync" "${bin_dir}/valo-cursors" "${bin_dir}/valo-agent-art"
    [[ -d "${data_home}/valo-skin/agent-art" ]] && note "Downloaded agent art kept in ${data_home/#${HOME}/\~}/valo-skin/agent-art (valo-agent-art --remove deletes it)"
    say "Done. Backups of edited files: ${backup_dir/#${HOME}/\~}"
    note "The shell itself is left installed at ${qs_dir/#${HOME}/\~}; remove it manually if you want."
    exit 0
fi

say "Distro: ${distro}   Source: ${src/#${HOME}/\~}"
confirm "Install Valo-skin?" || exit 0

# ------------------------------------------------------------------ packages

if (( do_deps )); then
    step "Packages"
    case "$distro" in
        arch)
            run sudo pacman -S --needed --noconfirm \
                base-devel git cmake ninja python \
                qt6-base qt6-declarative qt6-shadertools qt6-svg qt6-imageformats \
                pipewire aubio libqalculate lm_sensors fftw ddcutil brightnessctl \
                networkmanager swappy wl-clipboard grim slurp playerctl fish \
                hyprland xdg-desktop-portal-hyprland \
                kitty fastfetch qt5ct qt6ct ttf-cascadia-code-nerd
            aur=""
            for h in paru yay; do command -v "$h" >/dev/null && { aur="$h"; break; }; done
            if [[ -n "$aur" ]]; then
                run "$aur" -S --needed --noconfirm quickshell-git caelestia-cli
            else
                say "No AUR helper found: install quickshell-git (required) and caelestia-cli (optional) from the AUR."
            fi
            ;;
        fedora)
            note "Shell dependencies are installed by scripts/install-fedora.sh below."
            run sudo dnf install -y python3 kitty fastfetch qt5ct qt6ct
            ;;
        *)
            say "Unsupported distro for automatic packages; continuing (use --no-deps to silence)."
            ;;
    esac
fi

# ------------------------------------------------------------------ shell

if (( do_shell )); then
    step "Shell"
    if [[ "$distro" == fedora ]]; then
        # Builds into ~/.local and ~/.config/quickshell/caelestia (also installs its own build deps)
        run bash "${src}/scripts/install-fedora.sh"
    else
        modules="extras;plugin;shell;m3shapes"
        if [[ "$(realpath -m "$src")" == "$(realpath -m "$qs_dir")" ]]; then
            modules="extras;plugin;m3shapes" # cloned in place: QML is already where Quickshell looks
        fi
        run cmake -S "$src" -B "${src}/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR="$qs_dir" -DENABLE_MODULES="$modules"
        run cmake --build "${src}/build"
        run sudo cmake --install "${src}/build"
        [[ -d "$qs_dir" ]] && run sudo chown -R "${USER:-$(id -un)}" "$qs_dir"
    fi
fi

# ------------------------------------------------------------------ dotfiles

if (( do_dots )); then
    step "Tools and fonts"
    run mkdir -p "$bin_dir" "${data_home}/fonts/valo-skin"
    run install -m 0755 "${src}/dots/bin/valo-sync" "${src}/dots/bin/valo-cursors" "${src}/dots/bin/valo-agent-art" "$bin_dir/"
    run cp -f "${src}"/assets/fonts/*.ttf "${data_home}/fonts/valo-skin/"
    command -v fc-cache >/dev/null && run fc-cache -f "${data_home}/fonts/valo-skin"
    [[ ":${PATH}:" == *":${bin_dir}:"* ]] || say "Add ${bin_dir} to PATH so the shell can run valo-sync."

    step "Colours and cursor"
    run python3 "${bin_dir}/valo-sync" || run python3 "${src}/dots/bin/valo-sync"
    run python3 "${src}/dots/bin/valo-cursors"

    step "Hyprland"
    if [[ "$hypr_mode" == auto ]]; then
        if [[ -f "${config_home}/hypr/hyprland.lua" ]]; then hypr_mode=lua
        elif [[ -f "${config_home}/hypr/hyprland.conf" ]]; then hypr_mode=conf
        else hypr_mode=lua
        fi
    fi
    run mkdir -p "${config_home}/hypr"
    if [[ "$hypr_mode" == lua ]]; then
        run install -m 0644 "${src}/dots/hypr/valorant.lua" "${config_home}/hypr/valorant.lua"
        if [[ -f "${config_home}/hypr/hyprland.lua" ]]; then
            add_line "${config_home}/hypr/hyprland.lua" 'require("valorant")' "--"
        else
            say "No hyprland.lua yet: add  require(\"valorant\")  to it once you create one."
        fi
    else
        run install -m 0644 "${src}/dots/hypr/valorant.conf" "${config_home}/hypr/valorant.conf"
        add_line "${config_home}/hypr/hyprland.conf" "source = ~/.config/hypr/valorant.conf"
    fi

    step "Terminals"
    add_line "${config_home}/kitty/kitty.conf" "include valorant.conf"
    add_line "${config_home}/foot/foot.ini" "include=${config_home}/foot/valorant.ini"
    if [[ ! -f "${config_home}/alacritty/alacritty.toml" ]]; then
        run mkdir -p "${config_home}/alacritty"
        (( dry_run )) || printf '[general]\nimport = ["%s/alacritty/valorant.toml"] # %s\n' "$config_home" "$tag" \
            > "${config_home}/alacritty/alacritty.toml"
        say "created alacritty.toml"
    elif ! grep -qF valorant.toml "${config_home}/alacritty/alacritty.toml"; then
        say "Alacritty: add \"${config_home}/alacritty/valorant.toml\" to [general] import in alacritty.toml"
    fi
    if [[ "$(readlink "${config_home}/fastfetch/config.jsonc" 2>/dev/null)" == valorant.jsonc ]]; then
        note "already set up: fastfetch"
    elif [[ ! -e "${config_home}/fastfetch/config.jsonc" ]]; then
        run ln -s valorant.jsonc "${config_home}/fastfetch/config.jsonc"
        say "fastfetch now uses the Valorant config"
    else
        note "fastfetch: you have a config already; try  fastfetch -c valorant"
    fi

    step "GTK and Qt"
    # CSS only honours @import before any other rule, so these go at the top
    ADD_LINE_PREPEND=1 add_line "${config_home}/gtk-3.0/gtk.css" "@import 'valorant.css';" "/*" " */"
    ADD_LINE_PREPEND=1 add_line "${config_home}/gtk-4.0/gtk.css" "@import 'valorant.css';" "/*" " */"
    for ct in qt5ct qt6ct; do
        backup "${config_home}/${ct}/${ct}.conf"
        run mkdir -p "${config_home}/${ct}"
        ini_set "${config_home}/${ct}/${ct}.conf" Appearance custom_palette true
        ini_set "${config_home}/${ct}/${ct}.conf" Appearance color_scheme_path "${config_home}/${ct}/colors/valorant.conf"
    done
    say "qt5ct/qt6ct use the Valorant palette"

    step "Apps"
    # btop: select the generated theme
    if [[ -f "${config_home}/btop/btop.conf" ]]; then
        backup "${config_home}/btop/btop.conf"
        run sed -i 's|^color_theme = .*|color_theme = "valorant"|' "${config_home}/btop/btop.conf"
        say "btop uses the Valorant theme"
    fi
    # Konsole: Valorant profile as default, HUD tab bar
    if command -v konsole >/dev/null || [[ -f "${config_home}/konsolerc" ]]; then
        backup "${config_home}/konsolerc"
        kde_set "${config_home}/konsolerc" "Desktop Entry" DefaultProfile Valorant.profile
        kde_set "${config_home}/konsolerc" TabBar TabBarUseUserStyleSheet true
        kde_set "${config_home}/konsolerc" TabBar TabBarUserStyleSheetFile "file://${data_home}/valo-skin/konsole-tabs.css"
        say "Konsole uses the Valorant profile (new windows)"
    fi
    # VS Code family: set the colour theme when settings.json is plain JSON (left alone if it has comments)
    for d in Code "Code - OSS" VSCodium Cursor; do
        settings="${config_home}/${d}/User/settings.json"
        [[ -d "${config_home}/${d}" ]] || continue
        backup "$settings"
        if (( ! dry_run )) && python3 - "$settings" <<'PY'
import json, os, sys
path = sys.argv[1]
data = {}
if os.path.exists(path):
    try:
        data = json.load(open(path))
    except ValueError:
        sys.exit(1)  # JSONC with comments: don't touch
data["workbench.colorTheme"] = "Valorant (Valo-skin)"
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(data, open(path, "w"), indent=4)
PY
        then
            say "${d}: colour theme set to Valorant (Valo-skin)"
        else
            note "${d}: pick \"Valorant (Valo-skin)\" in Preferences → Color Theme"
        fi
    done
    command -v nvim >/dev/null && note "Neovim: add  vim.cmd.colorscheme('valorant')  to your config"
    for d in vesktop Vencord equibop; do
        [[ -d "${config_home}/${d}" ]] && note "${d}: enable valorant.theme.css in Settings → Themes"
    done
    if command -v spicetify >/dev/null; then
        run spicetify config current_theme Valorant color_scheme agent
        run spicetify apply || note "spicetify apply failed; run it manually after spicetify backup"
    fi

    if (( do_firefox )); then
        step "Firefox"
        found=0
        for base in "${HOME}/.mozilla/firefox" "${HOME}/.librewolf" "${HOME}/.zen"; do
            [[ -f "${base}/profiles.ini" ]] || continue
            while IFS= read -r rel; do
                prof="${base}/${rel}"
                [[ -d "$prof" ]] || continue
                found=1
                run mkdir -p "${prof}/chrome"
                run touch "${prof}/chrome/.valo-skin"
                run install -m 0644 "${src}/dots/firefox/valorant.css" "${prof}/chrome/valorant.css"
                ADD_LINE_PREPEND=1 add_line "${prof}/chrome/userChrome.css" '@import "valorant-colors.css"; @import "valorant.css";' "/*" " */"
                add_line "${prof}/user.js" 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' "//"
            done < <(sed -n 's/^Path=//p' "${base}/profiles.ini")
        done
        if (( found )); then
            run python3 "${bin_dir}/valo-sync" --only firefox --quiet || true
            say "Firefox profiles themed (restart Firefox)"
        else
            say "No Firefox/LibreWolf/Zen profiles found"
        fi
    fi

    if command -v gsettings >/dev/null; then
        run gsettings set org.gnome.desktop.interface cursor-theme Valo-Crosshair 2>/dev/null || true
        run gsettings set org.gnome.desktop.interface font-name "Barlow 11" 2>/dev/null || true
    fi
    backup "${HOME}/.icons/default/index.theme"
    run mkdir -p "${HOME}/.icons/default"
    (( dry_run )) || printf '[Icon Theme]\nInherits=Valo-Crosshair\n' > "${HOME}/.icons/default/index.theme"
    say "cursor theme: Valo-Crosshair"
fi

# ------------------------------------------------------------------ login + boot (opt-in)

# Player name: --player, else valorant.json -> player.name, else the account's full name
player_get() {
    python3 - <<'PY' 2>/dev/null || true
import json, os, pwd
path = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "caelestia/valorant.json")
name = ""
try:
    name = (json.load(open(path)).get("player") or {}).get("name", "").strip()
except Exception:
    pass
if not name:
    name = pwd.getpwuid(os.getuid()).pw_gecos.split(",")[0].strip()
print(name)
PY
}

player_save() {
    (( dry_run )) && { printf '  %s[dry-run]%s save player.name = %s\n' "$dim" "$off" "$1"; return; }
    python3 - "$1" <<'PY'
import json, os, sys
path = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "caelestia/valorant.json")
os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    data = json.load(open(path))
except Exception:
    data = {}
data.setdefault("player", {})["name"] = sys.argv[1]
with open(path, "w") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
PY
}

# Escapes a string for the right-hand side of a sed s||| expression
sed_escape() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

scheme_get() {
    python3 - "$1" "$2" <<'PY' 2>/dev/null || echo "$2"
import json, os, sys
path = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"), "caelestia/valorant-scheme.json")
try:
    d = json.load(open(path))
    v = {"accent": "#" + d["colours"]["primary"], "agent": d.get("flavour", ""), "name": d.get("agentName", "")}[sys.argv[1]]
    print(v or sys.argv[2])
except Exception:
    print(sys.argv[2])
PY
}

if (( do_agent_art )); then
    step "Agent art"
    run python3 "${src}/dots/bin/valo-agent-art" || say "Couldn't download agent art (offline?); run valo-agent-art later"
fi

if [[ -n "$player_name" ]]; then
    step "Player"
    player_save "$player_name"
    say "player.name = ${player_name} (lock screen, dashboard, welcome banner)"
fi
player="${player_name:-$(player_get)}"

if (( do_sddm )); then
    step "SDDM login theme"
    if (( do_deps )); then
        case "$distro" in
            arch) run sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-declarative ;;
            fedora)
                # Fedora 44 KDE ships Plasma's own login manager; SDDM needs a greeter
                # compositor: KWin's if Plasma is installed, else the X11 one
                run sudo dnf install -y sddm qt6-qtsvg qt6-qtdeclarative \
                    && { run sudo dnf install -y sddm-wayland-plasma 2>/dev/null || run sudo dnf install -y sddm-x11 || true; }
                ;;
        esac
    fi
    theme=/usr/share/sddm/themes/valo-skin
    agent="$(scheme_get agent valorant)"
    run sudo mkdir -p "$theme"
    run sudo cp -r "${src}/themes/sddm/valo-skin/." "$theme/"
    run sudo cp "${src}/assets/fonts/BebasNeue-Regular.ttf" "${src}/assets/fonts/Oswald-Variable.ttf" \
        "${src}/assets/fonts/Barlow-Regular.ttf" "${src}/assets/fonts/MaterialSymbolsSharp.ttf" "${theme}/assets/"
    wall="${src}/assets/wallpapers/agents/${agent}.webp"
    [[ -f "$wall" ]] || wall="${src}/assets/wallpaper.webp"
    run sudo cp "$wall" "${theme}/assets/background.webp"
    art="${data_home}/valo-skin/agent-art/${agent}.png"
    if [[ -f "$art" ]]; then
        run sudo cp "$art" "${theme}/assets/agent.png"
        run sudo sed -i "s|^agentArt=.*|agentArt=assets/agent.png|" "${theme}/theme.conf"
    fi
    run sudo sed -i -e "s|^accent=.*|accent=$(scheme_get accent '#ff4655')|" \
        -e "s|^agentName=.*|agentName=$(scheme_get name Valorant)|" "${theme}/theme.conf"
    if [[ -n "$player" ]]; then
        run sudo sed -i -e "s|^playerUser=.*|playerUser=$(sed_escape "${USER:-$(id -un)}")|" \
            -e "s|^playerName=.*|playerName=$(sed_escape "$player")|" \
            -e "s|^headline=.*|headline=$(sed_escape "$player")|" "${theme}/theme.conf"
    fi
    run sudo mkdir -p /etc/sddm.conf.d
    if (( ! dry_run )); then
        printf '[Theme]\nCurrent=valo-skin\n' | sudo tee /etc/sddm.conf.d/10-valo-skin.conf >/dev/null
    fi
    say "SDDM theme set (re-run with --sddm after switching agents to update its accent and wallpaper)"
    # Make SDDM the login manager, remembering the previous one for --uninstall
    if command -v systemctl >/dev/null; then
        current_dm="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service)"
        [[ "$current_dm" == display-manager ]] && current_dm="" # no login manager enabled
        if [[ "$current_dm" != sddm ]]; then
            if [[ -n "$current_dm" ]]; then
                run mkdir -p "${data_home}/valo-skin"
                (( dry_run )) || printf '%s\n' "$current_dm" > "${data_home}/valo-skin/dm-previous"
                run sudo systemctl disable "${current_dm}.service"
            fi
            run sudo systemctl enable -f sddm.service
            say "Login manager: ${current_dm:-none} -> sddm (takes effect after a reboot)"
        fi
    fi
fi

if (( do_plymouth )); then
    step "Plymouth boot splash"
    if (( do_deps )); then
        case "$distro" in
            arch) run sudo pacman -S --needed --noconfirm plymouth ;;
            fedora) run sudo dnf install -y plymouth plymouth-scripts plymouth-plugin-script plymouth-plugin-label ;;
        esac
    fi
    if command -v plymouth-set-default-theme >/dev/null; then
        current="$(plymouth-set-default-theme 2>/dev/null || true)"
        if [[ -n "$current" && "$current" != valo-skin ]]; then
            run mkdir -p "${data_home}/valo-skin"
            (( dry_run )) || printf '%s\n' "$current" > "${data_home}/valo-skin/plymouth-previous"
        fi
        run sudo mkdir -p /usr/share/plymouth/themes/valo-skin
        run sudo cp -r "${src}/themes/plymouth/valo-skin/." /usr/share/plymouth/themes/valo-skin/
        if [[ -n "$player" ]]; then
            ply_name="$(printf '%s' "$player" | tr '[:lower:]' '[:upper:]' | tr -d '"\\')"
            run sudo sed -i "s|^player_name = \"\";|player_name = \"$(sed_escape "$ply_name")\";|" \
                /usr/share/plymouth/themes/valo-skin/valo-skin.script
        fi
        run sudo mkdir -p /usr/share/fonts/valo-skin
        run sudo cp "${src}/assets/fonts/Oswald-Variable.ttf" "${src}/assets/fonts/Barlow-Regular.ttf" /usr/share/fonts/valo-skin/
        if [[ "$distro" == fedora ]]; then
            run sudo plymouth-set-default-theme -R valo-skin
        else
            run sudo plymouth-set-default-theme valo-skin
            if grep -qE '^HOOKS=.*plymouth' /etc/mkinitcpio.conf 2>/dev/null; then
                run sudo mkinitcpio -P
            else
                say "Add the 'plymouth' hook to HOOKS in /etc/mkinitcpio.conf and run: sudo mkinitcpio -P"
            fi
        fi
        grep -qw splash /proc/cmdline || say "Add 'splash' (and 'quiet') to your kernel command line to see the splash."
    else
        say "plymouth-set-default-theme not found; install Plymouth first."
    fi
fi

if (( do_dev )); then
    step "Coding tools"
    dev_args=()
    (( assume_yes )) && dev_args+=(-y)
    (( dry_run )) && dev_args+=(--dry-run)
    bash "${src}/scripts/dev-tools.sh" "${dev_args[@]}" || say "Some coding tools failed; re-run scripts/dev-tools.sh"
fi

step "Done"
say "Start the shell with  qs -c caelestia  (or log into Hyprland)."
say "Switch agents: launcher \">agent\", Settings → Wallpaper & style, or SUPER+ALT+←/→."
[[ -d "$backup_dir" ]] && say "Backups of edited files: ${backup_dir/#${HOME}/\~}"
exit 0
