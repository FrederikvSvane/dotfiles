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

if [ "$MODE" = root ]; then
    log "Installing zsh, git, curl, screen, and gh"
    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y zsh git curl screen
        $SUDO apt-get install -y gh 2>/dev/null || echo "gh not in apt repos; install manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y zsh git curl screen
        $SUDO dnf install -y gh 2>/dev/null || echo "gh not in dnf repos; install manually"
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --needed --noconfirm zsh git curl screen github-cli
    elif command -v brew >/dev/null 2>&1; then
        brew install zsh gh screen
    else
        echo "No supported package manager found. Install zsh, git, curl, screen, and gh yourself, then re-run." >&2
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
fi

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
echo "  3. Log out and back in (or run 'exec zsh') to start using zsh."
