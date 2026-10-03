#!/usr/bin/env bash
# Valo-skin dev tools: one-shot installer for coding tools on Arch and Fedora.
#
#   scripts/dev-tools.sh                 interactive checklist (recommended modules preselected)
#   scripts/dev-tools.sh --all -y        everything, no questions
#   scripts/dev-tools.sh --only python,jupyter,vscode
#   scripts/dev-tools.sh --list          show modules
#   scripts/dev-tools.sh --dry-run ...   print commands only
#
# Safe to re-run: package managers skip what's installed, language toolchains are only
# bootstrapped once, and nothing in your dotfiles is rewritten.
# Testing: VALO_DISTRO=arch|fedora overrides detection, VALO_SKIP_PKG=1 skips distro packages.
set -Eeuo pipefail

readonly data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly bin_dir="${HOME}/.local/bin"
readonly jupyter_env="${data_home}/valo-skin/jupyter"
readonly datasci_env="${HOME}/.venvs/datasci"

dry_run=0
assume_yes=0
selection=""
list_only=0

# ------------------------------------------------------------------ modules
# id | description | recommended(1/0)
readonly modules=(
    "core|Build essentials + CLI kit: gcc, clang, cmake, ninja, gdb, ripgrep, fd, fzf, bat, eza, jq, tmux, direnv|1"
    "git|GitHub CLI, lazygit, git-delta|1"
    "vscode|Visual Studio Code + recommended extensions (Python, Jupyter, Rust, Go, C/C++, Docker, ESLint, Prettier, GitLens)|1"
    "vscodium|VSCodium (telemetry-free VS Code build)|0"
    "neovim|Neovim + Helix editors|1"
    "jetbrains|JetBrains Toolbox (installs IntelliJ, PyCharm, CLion, ... on demand)|0"
    "python|Python, pip, pipx, uv, ruff, pyright|1"
    "jupyter|JupyterLab + Notebook in an isolated env, Valorant-themed via valo-sync|1"
    "datasci|Data-science Jupyter kernel: numpy, pandas, polars, matplotlib, seaborn, scipy, scikit-learn|0"
    "node|Node.js, npm, pnpm and yarn (corepack), TypeScript|1"
    "rust|Rust toolchain via rustup (stable, clippy, rustfmt, rust-analyzer)|1"
    "go|Go toolchain + gopls|1"
    "java|OpenJDK 21, Maven, Gradle|0"
    "cpp|C/C++ extras: clangd/clang-tools, lldb, valgrind, ccache, meson|1"
    "docker|Docker Engine + Compose + Buildx (service enabled, user added to docker group)|0"
    "podman|Podman + podman-compose (rootless containers)|0"
    "databases|SQLite, PostgreSQL, Valkey (Redis-compatible) - installed, not started|0"
    "cloud|kubectl, helm, OpenTofu, AWS CLI|0"
    "gui|Flatpak GUI tools: Postman, DBeaver, GitHub Desktop|0"
)

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    echo
    echo "Modules:"
    print_modules
}

print_modules() {
    local m id desc rec
    for m in "${modules[@]}"; do
        IFS='|' read -r id desc rec <<<"$m"
        printf '  %-10s %s%s\n' "$id" "$desc" "$([[ $rec == 1 ]] && echo '  [recommended]')"
    done
}

for arg in "$@"; do
    case "$arg" in
        --all) selection=all ;;
        --only=*) selection="${arg#--only=}" ;;
        --only) selection=__next ;;
        --list) list_only=1 ;;
        --dry-run) dry_run=1 ;;
        -y|--yes) assume_yes=1 ;;
        -h|--help) usage; exit 0 ;;
        *)
            if [[ "$selection" == __next ]]; then
                selection="$arg"
            else
                echo "Unknown option: ${arg}" >&2; usage >&2; exit 2
            fi
            ;;
    esac
done

if (( list_only )); then
    print_modules
    exit 0
fi

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
has() { command -v "$1" >/dev/null 2>&1; }

if [[ "${EUID}" -eq 0 && -z "${VALO_ALLOW_ROOT:-}" ]]; then
    echo "Run as your normal user; sudo is used where needed." >&2
    exit 1
fi

# ------------------------------------------------------------------ distro

distro="${VALO_DISTRO:-}"
if [[ -z "$distro" && -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${ID:-}" == arch || " ${ID_LIKE:-} " == *" arch "* ]]; then distro=arch
    elif [[ "${ID:-}" == fedora ]]; then distro=fedora
    fi
fi
if [[ "$distro" != arch && "$distro" != fedora ]]; then
    echo "Supported: Arch (and derivatives) and Fedora. Detected: ${distro:-unknown}" >&2
    exit 1
fi

aur=""
if [[ "$distro" == arch ]]; then
    for h in paru yay; do has "$h" && { aur="$h"; break; }; done
fi

pkgs() {
    # pkgs <arch packages...> -- <fedora packages...>
    local arch=() fedora=() side=arch
    for p in "$@"; do
        if [[ "$p" == -- ]]; then side=fedora; continue; fi
        if [[ "$side" == arch ]]; then arch+=("$p"); else fedora+=("$p"); fi
    done
    if [[ -n "${VALO_SKIP_PKG:-}" ]]; then
        note "VALO_SKIP_PKG set: skipping distro packages"
    elif [[ "$distro" == arch && ${#arch[@]} -gt 0 ]]; then
        run sudo pacman -S --needed --noconfirm "${arch[@]}"
    elif [[ "$distro" == fedora && ${#fedora[@]} -gt 0 ]]; then
        run sudo dnf install -y "${fedora[@]}"
    fi
}

aur_pkgs() {
    if [[ -n "$aur" ]]; then
        run "$aur" -S --needed --noconfirm "$@"
    else
        say "AUR helper (paru/yay) not found: install manually from the AUR: $*"
    fi
}

flatpak_apps() {
    pkgs flatpak -- flatpak
    run flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    run flatpak install --user -y flathub "$@"
}

link_bin() {
    run mkdir -p "$bin_dir"
    local f
    for f in "$@"; do
        run ln -sf "$f" "${bin_dir}/$(basename "$f")"
    done
}

# ------------------------------------------------------------------ installers

install_core() {
    pkgs base-devel git cmake ninja gcc clang gdb make pkgconf curl wget unzip zip jq ripgrep fd fzf bat eza \
        zoxide tmux htop btop tree direnv man-db \
        -- @development-tools git cmake ninja-build gcc gcc-c++ clang gdb make pkgconf-pkg-config curl wget \
        unzip zip jq ripgrep fd-find fzf bat eza zoxide tmux htop btop tree direnv man-db
}

install_git() {
    pkgs github-cli lazygit git-delta -- gh git-delta
    if [[ "$distro" == fedora ]]; then
        run sudo dnf copr enable -y atim/lazygit
        run sudo dnf install -y lazygit
    fi
    if has delta; then
        note "Use delta as git pager: git config --global core.pager delta"
    fi
}

readonly vscode_extensions=(
    ms-python.python ms-toolsai.jupyter charliermarsh.ruff rust-lang.rust-analyzer golang.go
    llvm-vs-code-extensions.vscode-clangd ms-azuretools.vscode-docker dbaeumer.vscode-eslint
    esbenp.prettier-vscode eamodio.gitlens
)

install_vscode_extensions() {
    local cli="$1" ext
    for ext in "${vscode_extensions[@]}"; do
        run "$cli" --install-extension "$ext" --force || note "skipped ${ext}"
    done
}

install_vscode() {
    if [[ "$distro" == arch ]]; then
        if [[ -n "$aur" ]]; then
            aur_pkgs visual-studio-code-bin # Microsoft build: full marketplace
        else
            pkgs code -- # Arch's OSS build (Open VSX)
        fi
    else
        run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        if (( ! dry_run )); then
            printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
                | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
        fi
        run sudo dnf install -y code
    fi
    if has code || (( dry_run )); then
        install_vscode_extensions code
    fi
    if has valo-sync; then
        run valo-sync --only vscode --quiet
    fi
}

install_vscodium() {
    if [[ "$distro" == arch ]]; then
        aur_pkgs vscodium-bin
    else
        run sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
        if (( ! dry_run )); then
            printf '[gitlab.com_paulcarroty_vscodium_repo]\nname=VSCodium\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n' \
                | sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null
        fi
        run sudo dnf install -y codium
    fi
    if has codium || (( dry_run )); then
        install_vscode_extensions codium
    fi
    if has valo-sync; then
        run valo-sync --only vscode --quiet
    fi
}

install_neovim() {
    pkgs neovim helix python-pynvim -- neovim helix python3-neovim
    note "Valorant colorscheme: vim.cmd.colorscheme('valorant') (generated by valo-sync)"
}

install_jetbrains() {
    local dest="${data_home}/JetBrains/Toolbox"
    pkgs fuse2 -- fuse-libs
    if [[ -x "${dest}/bin/jetbrains-toolbox" ]]; then
        note "JetBrains Toolbox already installed"
        return
    fi
    local api='https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' url=""
    run mkdir -p "$dest"
    if (( dry_run )); then
        note "would download the latest Toolbox from ${api}"
    else
        url="$(curl -fsSL "$api" | python3 -c 'import json,sys; print(json.load(sys.stdin)["TBA"][0]["downloads"]["linux"]["link"])')" \
            || { say "Couldn't reach JetBrains; download Toolbox from jetbrains.com/toolbox-app"; return 1; }
        curl -fsSL "$url" | tar -xz -C "$dest" --strip-components=1
    fi
    link_bin "${dest}/bin/jetbrains-toolbox"
    say "Run jetbrains-toolbox to install IDEs"
}

install_python() {
    pkgs python python-pip python-pipx uv ruff pyright -- python3 python3-pip pipx uv ruff
    if [[ "$distro" == fedora ]] && ! has pyright; then
        if has npm; then
            run npm install -g --prefix "${HOME}/.local" pyright
        fi
    fi
    run pipx ensurepath >/dev/null 2>&1 || true
}

uv_bin() {
    if has uv; then echo uv; elif [[ -x "${HOME}/.local/bin/uv" ]]; then echo "${HOME}/.local/bin/uv"; else echo ""; fi
}

install_jupyter() {
    has uv || install_python
    local uv
    uv="$(uv_bin)"
    if [[ -z "$uv" ]]; then
        if (( dry_run )); then
            uv=uv
        else
            say "uv not available; install the python module first"
            return 1
        fi
    fi
    run "$uv" venv --allow-existing "$jupyter_env"
    run "$uv" pip install --python "${jupyter_env}/bin/python" -U jupyterlab notebook ipykernel jupyterlab-git jupyterlab-lsp python-lsp-server
    link_bin "${jupyter_env}/bin/jupyter" "${jupyter_env}/bin/jupyter-lab" "${jupyter_env}/bin/jupyter-notebook"
    run "${jupyter_env}/bin/python" -m ipykernel install --user --name valo-python --display-name "Python (Valo-skin)"

    # Theme: dark base + valo-sync's custom.css
    run mkdir -p "${HOME}/.jupyter" "${data_home}/jupyter/lab/settings"
    local cfg="${HOME}/.jupyter/jupyter_lab_config.py"
    if ! grep -qs "custom_css" "$cfg"; then
        (( dry_run )) || printf '\nc.LabApp.custom_css = True  # valo-skin: load ~/.jupyter/custom/custom.css\n' >> "$cfg"
    fi
    local overrides="${data_home}/jupyter/lab/settings/overrides.json"
    [[ -e "$overrides" ]] || { (( dry_run )) || printf '{\n  "@jupyterlab/apputils-extension:themes": { "theme": "JupyterLab Dark" }\n}\n' > "$overrides"; }
    if has valo-sync; then
        run valo-sync --only jupyter --quiet
    fi
    say "JupyterLab: run  jupyter lab  (Notebook: jupyter notebook)"
}

install_datasci() {
    has uv || install_python
    local uv
    uv="$(uv_bin)"
    [[ -n "$uv" ]] || uv=uv
    run "$uv" venv --allow-existing "$datasci_env"
    run "$uv" pip install --python "${datasci_env}/bin/python" -U ipykernel numpy pandas polars pyarrow matplotlib \
        seaborn scipy scikit-learn statsmodels plotly tqdm
    run "${datasci_env}/bin/python" -m ipykernel install --user --name datasci --display-name "Python (data science)"
    say "Kernel \"Python (data science)\" is available in Jupyter and VS Code"
}

install_node() {
    pkgs nodejs npm -- nodejs npm
    if has corepack || (( dry_run )); then
        run corepack enable --install-directory "$bin_dir" || note "corepack enable failed; use npm i -g pnpm"
    fi
    run npm install -g --prefix "${HOME}/.local" typescript typescript-language-server
}

install_rust() {
    pkgs rustup -- rustup
    if [[ "$distro" == fedora ]] && ! [[ -x "${HOME}/.cargo/bin/rustc" ]]; then
        run rustup-init -y --no-modify-path
    fi
    local rustup=rustup
    [[ -x "${HOME}/.cargo/bin/rustup" ]] && rustup="${HOME}/.cargo/bin/rustup"
    run "$rustup" default stable
    run "$rustup" component add clippy rustfmt rust-analyzer
    note "Add ~/.cargo/bin to PATH if it isn't already"
}

install_go() {
    pkgs go gopls -- golang golang-x-tools-gopls
}

install_java() {
    pkgs jdk21-openjdk maven gradle -- java-21-openjdk-devel maven gradle
}

install_cpp() {
    pkgs clang lldb valgrind ccache meson bear -- clang-tools-extra lldb valgrind ccache meson bear
}

install_docker() {
    if [[ "$distro" == arch ]]; then
        pkgs docker docker-compose docker-buildx --
    else
        run sudo dnf install -y dnf-plugins-core
        run sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo --overwrite
        run sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    run sudo systemctl enable --now docker
    run sudo usermod -aG docker "${USER:-$(id -un)}"
    say "Log out and back in to use docker without sudo"
}

install_podman() {
    pkgs podman podman-compose -- podman podman-compose
}

install_databases() {
    pkgs sqlite postgresql valkey -- sqlite postgresql-server valkey
    note "Not started. PostgreSQL first run: see your distro's initdb instructions; then systemctl enable --now postgresql"
}

install_cloud() {
    pkgs kubectl helm opentofu aws-cli-v2 -- kubernetes-client helm opentofu awscli2
}

install_gui() {
    flatpak_apps com.getpostman.Postman io.dbeaver.DBeaverCommunity io.github.shiftey.Desktop
}

# ------------------------------------------------------------------ selection

all_ids=()
recommended=()
for m in "${modules[@]}"; do
    IFS='|' read -r id _ rec <<<"$m"
    all_ids+=("$id")
    [[ "$rec" == 1 ]] && recommended+=("$id")
done

chosen=()
if [[ "$selection" == all ]]; then
    chosen=("${all_ids[@]}")
elif [[ -n "$selection" ]]; then
    IFS=',' read -r -a chosen <<<"$selection"
    for id in "${chosen[@]}"; do
        printf '%s\n' "${all_ids[@]}" | grep -qx "$id" || { echo "Unknown module: ${id}" >&2; exit 2; }
    done
elif (( assume_yes )) || [[ ! -t 0 ]]; then
    chosen=("${recommended[@]}")
elif has whiptail; then
    args=()
    for m in "${modules[@]}"; do
        IFS='|' read -r id desc rec <<<"$m"
        args+=("$id" "$desc" "$([[ $rec == 1 ]] && echo ON || echo OFF)")
    done
    picked="$(whiptail --title "Valo-skin dev tools" --checklist "Select loadout (space to toggle):" 24 110 16 "${args[@]}" 3>&1 1>&2 2>&3)" || exit 0
    read -r -a chosen <<<"${picked//\"/}"
else
    echo "Modules:"
    print_modules
    read -r -p "Modules to install (comma-separated, Enter = recommended): " reply
    if [[ -z "$reply" ]]; then chosen=("${recommended[@]}"); else IFS=',' read -r -a chosen <<<"${reply// /}"; fi
fi

say "Distro: ${distro}${aur:+ (AUR: ${aur})}   Loadout: ${chosen[*]}"
if (( ! assume_yes && ! dry_run )) && [[ -t 0 ]]; then
    read -r -p "Install? [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]] || exit 0
fi

if [[ "$distro" == arch && -z "${VALO_SKIP_PKG:-}" ]]; then
    run sudo pacman -Sy --noconfirm >/dev/null
fi
failed=()
for id in "${chosen[@]}"; do
    step "$id"
    # Bash ignores `set -e` inside functions called from `if`, so run each module in a subshell
    # with errexit on and check its status explicitly.
    set +e
    (set -e; "install_${id}")
    rc=$?
    set -e
    if (( rc != 0 )); then
        failed+=("$id")
        say "${id}: failed (continuing)"
    fi
done

step "Done"
if (( ${#failed[@]} )); then
    say "Failed modules: ${failed[*]} (re-run with --only $(IFS=,; echo "${failed[*]}"))"
else
    say "Loadout ready."
fi
[[ ":${PATH}:" == *":${bin_dir}:"* ]] || say "Add ${bin_dir} to PATH."
