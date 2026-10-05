#!/usr/bin/env bash
# Terminal environment setup: zsh + oh-my-zsh + powerlevel10k + my configs.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/FrederikvSvane/dotfiles/main/setup.sh | bash
#
# Safe to re-run. Existing config files are backed up before they are replaced.

set -euo pipefail

RAW="https://raw.githubusercontent.com/FrederikvSvane/dotfiles/main"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log() { printf '\n==> %s\n' "$1"; }

# --- privileges -------------------------------------------------------------
# Root mode: running as root, or sudo is usable. Otherwise user mode installs
# everything under ~/.local and never calls sudo.
if [ "$(id -u)" -eq 0 ]; then
    MODE=root
    SUDO=""
elif command -v sudo >/dev/null 2>&1 &&
    { sudo -n true 2>/dev/null || id -Gn | grep -qwE 'sudo|wheel|admin'; }; then
    MODE=root
    SUDO="sudo"
else
    MODE=user
    SUDO=""
fi
log "Running in $MODE mode"

# --- packages ---------------------------------------------------------------
install_gh_user() {
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64)               arch=amd64 ;;
        Linux-aarch64|Linux-arm64)  arch=arm64 ;;
        *) echo "No gh binary for $(uname -sm); install manually: https://github.com/cli/cli/releases"; return ;;
    esac
    version="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest |
        sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')"
    if [ -z "$version" ]; then
        echo "Could not determine the latest gh version; install manually: https://github.com/cli/cli/releases"
        return
    fi
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/cli/cli/releases/download/v$version/gh_${version}_linux_${arch}.tar.gz" |
        tar -xz -C "$tmp"
    cp "$tmp/gh_${version}_linux_${arch}/bin/gh" "$HOME/.local/bin/gh"
    rm -rf "$tmp"
}

# --- neovim + LazyVim tooling ----------------------------------------------
# Latest GitHub release tag without the leading "v".
latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
        sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n1
}

# LazyVim needs nvim >= 0.11, which distro packages often lack.
# In root mode $SUDO is "sudo" (or empty when already root), so the install helpers use it directly.
nvim_ok() {
    command -v nvim >/dev/null 2>&1 &&
        nvim --headless '+if !has("nvim-0.11") | cquit 1 | endif' +qa >/dev/null 2>&1
}

install_nvim_release() { # $1 = install prefix for the unpacked tree, $2 = bin dir
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64)               asset=nvim-linux-x86_64 ;;
        Linux-aarch64|Linux-arm64)  asset=nvim-linux-arm64 ;;
        Darwin-arm64)               asset=nvim-macos-arm64 ;;
        Darwin-x86_64)              asset=nvim-macos-x86_64 ;;
        *) echo "No nvim binary for $(uname -sm); install manually: https://github.com/neovim/neovim/releases"; return 1 ;;
    esac
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/$asset.tar.gz" | tar -xz -C "$tmp" || { rm -rf "$tmp"; return 1; }
    $SUDO rm -rf "$1"
    $SUDO mkdir -p "$(dirname "$1")" "$2"
    $SUDO mv "$tmp/$asset" "$1"
    $SUDO ln -sf "$1/bin/nvim" "$2/nvim"
    rm -rf "$tmp"
}

# Single-binary tools from GitHub releases into ~/.local/bin (user mode only).
install_user_tools() {
    case "$(uname -s)-$(uname -m)" in
        Linux-x86_64)               a=x86_64; rg_t=x86_64-unknown-linux-musl;  lg_a=x86_64 ;;
        Linux-aarch64|Linux-arm64)  a=aarch64; rg_t=aarch64-unknown-linux-gnu; lg_a=arm64 ;;
        *) echo "Skipping ripgrep/fd/lazygit (no prebuilt binaries for $(uname -sm))"; return ;;
    esac
    tmp="$(mktemp -d)"
    if ! command -v rg >/dev/null 2>&1 && v="$(latest_tag BurntSushi/ripgrep)" && [ -n "$v" ]; then
        log "Installing ripgrep"
        curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/$v/ripgrep-$v-$rg_t.tar.gz" | tar -xz -C "$tmp" &&
            cp "$tmp"/ripgrep-*/rg "$HOME/.local/bin/rg" || echo "ripgrep install failed"
    fi
    if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1 && v="$(latest_tag sharkdp/fd)" && [ -n "$v" ]; then
        log "Installing fd"
        curl -fsSL "https://github.com/sharkdp/fd/releases/download/v$v/fd-v$v-$a-unknown-linux-gnu.tar.gz" | tar -xz -C "$tmp" &&
            cp "$tmp"/fd-*/fd "$HOME/.local/bin/fd" || echo "fd install failed"
    fi
    if ! command -v lazygit >/dev/null 2>&1 && v="$(latest_tag jesseduffield/lazygit)" && [ -n "$v" ]; then
        log "Installing lazygit"
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v$v/lazygit_${v}_Linux_$lg_a.tar.gz" | tar -xz -C "$tmp" lazygit &&
            cp "$tmp/lazygit" "$HOME/.local/bin/lazygit" || echo "lazygit install failed"
    fi
    rm -rf "$tmp"
}

if [ "$MODE" = root ]; then
    log "Installing zsh, git, curl, screen, tmux, and gh"
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y zsh git curl screen tmux ripgrep fd-find fzf build-essential unzip
        $SUDO apt-get install -y lazygit 2>/dev/null || true
        $SUDO apt-get install -y gh 2>/dev/null || echo "gh not in apt repos; install manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y zsh git curl screen tmux ripgrep fd-find fzf gcc make unzip
        $SUDO dnf install -y gh 2>/dev/null || echo "gh not in dnf repos; install manually"
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --needed --noconfirm zsh git curl screen tmux github-cli neovim ripgrep fd fzf lazygit base-devel unzip
    elif command -v brew >/dev/null 2>&1; then
        brew install zsh gh screen tmux neovim ripgrep fd fzf lazygit
    else
        echo "No supported package manager found. Install zsh, git, curl, screen, tmux, and gh yourself, then re-run." >&2
        exit 1
    fi
else
    log "No root access; installing missing tools to ~/.local"
    mkdir -p "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"

    for cmd in git curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd is required and cannot be installed without root. Ask an admin to install it, then re-run." >&2
            exit 1
        fi
    done

    if command -v zsh >/dev/null 2>&1; then
        log "zsh already installed"
    else
        log "Installing zsh (zsh-bin)"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install)" -- -q -d "$HOME/.local" -e no
    fi

    if command -v gh >/dev/null 2>&1; then
        log "gh already installed"
    else
        log "Installing gh"
        install_gh_user
    fi

    command -v screen >/dev/null 2>&1 || echo "screen is not installed and needs root to install; skipping."
    command -v tmux >/dev/null 2>&1 || echo "tmux is not installed and needs root to install; ~/.tmux.conf is still set up for when it is."
fi

# --- neovim -----------------------------------------------------------------
if nvim_ok; then
    log "nvim already installed (>= 0.11)"
else
    log "Installing neovim"
    if [ "$MODE" = root ]; then
        # Root mode: system-wide in /opt/nvim, linked into /usr/local/bin.
        install_nvim_release /opt/nvim /usr/local/bin || echo "Could not install nvim >= 0.11 automatically."
    else
        install_nvim_release "$HOME/.local/nvim" "$HOME/.local/bin" || echo "Could not install nvim automatically."
    fi
fi
if [ "$MODE" = user ]; then
    install_user_tools
fi
command -v cc >/dev/null 2>&1 || echo "No C compiler found; nvim-treesitter needs one (gcc/clang) to build parsers."

# --- oh-my-zsh --------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    log "oh-my-zsh already installed"
fi

# --- theme and plugins ------------------------------------------------------
clone_if_missing() {
    if [ -d "$2" ]; then
        log "$(basename "$2") already installed"
    else
        log "Installing $(basename "$2")"
        git clone --depth=1 "$1" "$2"
    fi
}
clone_if_missing https://github.com/romkatv/powerlevel10k.git      "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions   "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# --- config files -----------------------------------------------------------
fetch_config() {
    src="$RAW/$1"
    dest="$HOME/$2"
    if [ -f "$dest" ]; then
        cp "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
        log "Backed up existing $2, downloading new one"
    else
        log "Downloading $2"
    fi
    curl -fsSL "$src" -o "$dest"
}
fetch_config zshrc     .zshrc
fetch_config p10k.zsh  .p10k.zsh
fetch_config gitconfig .gitconfig
fetch_config screenrc  .screenrc
fetch_config tmux.conf .tmux.conf

# --- nvim config (LazyVim + catppuccin) -------------------------------------
# A whole directory, so clone the repo instead of fetching file by file.
NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
tmp="$(mktemp -d)"
if git clone --depth=1 https://github.com/FrederikvSvane/dotfiles.git "$tmp/dotfiles"; then
    if [ -e "$NVIM_DIR" ]; then
        mv "$NVIM_DIR" "$NVIM_DIR.bak.$(date +%Y%m%d%H%M%S)"
        log "Backed up existing nvim config"
    fi
    mkdir -p "$(dirname "$NVIM_DIR")"
    cp -R "$tmp/dotfiles/nvim" "$NVIM_DIR"
    if command -v nvim >/dev/null 2>&1; then
        log "Installing nvim plugins (pinned by lazy-lock.json)"
        nvim --headless "+Lazy! restore" +qa 2>&1 || echo "Plugin install failed; it will retry on first nvim launch."
    fi
else
    echo "Could not clone dotfiles; skipping nvim config."
fi
rm -rf "$tmp"

# --- default shell ----------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
BASHRC_MARKER="# dotfiles: start zsh"
if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    log "zsh is already the default shell"
elif [ "$MODE" = root ]; then
    log "Setting zsh as the default shell"
    grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | $SUDO tee -a /etc/shells >/dev/null
    $SUDO chsh -s "$ZSH_PATH" "$(id -un)" || chsh -s "$ZSH_PATH"
elif grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null &&
    { chsh -s "$ZSH_PATH" </dev/tty; } 2>/dev/null; then
    log "Set zsh as the default shell"
elif grep -qF "$BASHRC_MARKER" "$HOME/.bashrc" 2>/dev/null; then
    log "~/.bashrc already starts zsh"
else
    # Can't change the login shell without root, so have bash hand over to zsh.
    # SHLVL guard: running `bash` from inside zsh still gives you bash.
    log "Can't change the login shell; making ~/.bashrc start zsh instead"
    cat >> "$HOME/.bashrc" <<EOF

$BASHRC_MARKER (no permission to change the login shell)
if [ -t 1 ] && [ "\${SHLVL:-1}" -le 1 ] && [ -x "$ZSH_PATH" ]; then
    export SHELL="$ZSH_PATH"
    exec "$ZSH_PATH" -l
fi
EOF
fi

# --- done -------------------------------------------------------------------
log "Done. Remaining manual steps:"
echo "  1. Run 'gh auth login' so the git credential helper works."
echo "  2. If the prompt shows broken symbols, install the MesloLGS NF font in the"
echo "     terminal you are connecting FROM: https://github.com/romkatv/powerlevel10k#fonts"
echo "  3. Install a Nerd Font (e.g. JetBrainsMono Nerd Font) in your terminal for nvim icons."
echo "  4. Log out and back in (or run 'exec zsh') to start using zsh."
