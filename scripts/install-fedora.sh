#!/usr/bin/env bash
set -Eeuo pipefail

# Fedora 44 installer for the Caelestia shell source tree.
# The shell is installed into ~/.local and the Quickshell config into
# ~/.config/quickshell/caelestia, so rerunning this script is safe.

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly source_dir="$(cd -- "${script_dir}/.." && pwd)"
readonly config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
readonly local_prefix="${HOME}/.local"
readonly qml_dir="${local_prefix}/lib64/qt6/qml"
readonly lib_dir="${local_prefix}/lib64/caelestia"
readonly config_dir="${config_home}/quickshell/caelestia"
readonly launcher="${local_prefix}/bin/caelestia-shell"

enable_copr=0
enable_systemd=0

usage() {
    cat <<'EOF'
Usage: scripts/install-fedora.sh [options]

Build and install Caelestia for Fedora 44 into the current user's home.

Options:
  --enable-copr       Enable ashbuk/Hyprland-Fedora for Hyprland packages.
  --enable-systemd    Install and enable a user service for the shell.
  -h, --help          Show this help.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --enable-copr) enable_copr=1 ;;
        --enable-systemd) enable_systemd=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: ${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run this installer as your normal user, not root." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot identify the operating system (/etc/os-release is missing)." >&2
    exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != fedora ]]; then
    echo "This installer supports Fedora only (detected: ${ID:-unknown})." >&2
    exit 1
fi
if [[ "${VERSION_ID%%.*}" != 44 ]]; then
    echo "Warning: this installer targets Fedora 44; detected Fedora ${VERSION_ID:-unknown}." >&2
fi

if ! command -v dnf >/dev/null; then
    echo "dnf is required." >&2
    exit 1
fi

if (( enable_copr )); then
    sudo dnf install -y 'dnf-command(copr)'
    sudo dnf copr enable -y ashbuk/Hyprland-Fedora
fi

# Fedora names, rather than Arch/Nix names from the upstream packaging.
readonly packages=(
    cmake ninja-build gcc-c++ pkgconf-pkg-config git
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel
    qt6-qtimageformats qt6-qtsvg-devel pipewire-devel aubio-devel
    cava fftw-devel libqalculate-devel lm_sensors-devel
    NetworkManager ddcutil brightnessctl swappy wl-clipboard fish
    hyprland xdg-desktop-portal xdg-desktop-portal-hyprland
    wireplumber pipewire-utils upower polkit grim slurp playerctl
    mako hyprpaper
    google-noto-sans-fonts google-rubik-fonts cascadia-code-nf-fonts
)

sudo dnf install -y "${packages[@]}"

mkdir -p "${config_dir}" "${qml_dir}" "${lib_dir}" "${local_prefix}/bin"

cmake -S "${source_dir}" -B "${source_dir}/build-fedora" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DVERSION="$(git -C "${source_dir}" describe --tags --abbrev=0 2>/dev/null || printf '0.0.0')" \
    -DGIT_REVISION="$(git -C "${source_dir}" rev-parse HEAD)" \
    -DCMAKE_INSTALL_PREFIX="${local_prefix}" \
    -DINSTALL_LIBDIR="${lib_dir}" \
    -DINSTALL_QMLDIR="${qml_dir}" \
    -DINSTALL_QSCONFDIR="${config_dir}" \
    -DDISTRIBUTOR="fedora"
cmake --build "${source_dir}/build-fedora"
cmake --install "${source_dir}/build-fedora"

cat > "${launcher}" <<EOF
#!/usr/bin/env bash
set -e
export PATH="${local_prefix}/bin\${PATH:+:\${PATH}}"
export CAELESTIA_LIB_DIR="${lib_dir}"
export QML2_IMPORT_PATH="${qml_dir}\${QML2_IMPORT_PATH:+:\${QML2_IMPORT_PATH}}"
exec qs -p "${config_dir}" "\$@"
EOF
chmod 0755 "${launcher}"

if (( enable_systemd )); then
    mkdir -p "${config_home}/systemd/user"
    cat > "${config_home}/systemd/user/caelestia.service" <<EOF
[Unit]
Description=Caelestia shell
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=exec
ExecStart=%h/.local/bin/caelestia-shell
Restart=on-failure
RestartSec=5s
Environment=QT_QPA_PLATFORM=wayland

[Install]
WantedBy=graphical-session.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now caelestia.service
fi

echo "Caelestia installed for Fedora at ${config_dir}."
echo "Start it with: ${launcher}"
echo "Ensure ${local_prefix}/bin is on PATH."
