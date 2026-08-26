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

# --- packages ---------------------------------------------------------------
log "Installing zsh, git, curl"
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y zsh git curl
    sudo apt-get install -y gh 2>/dev/null || echo "gh not in apt repos; install manually: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh git curl
    sudo dnf install -y gh 2>/dev/null || echo "gh not in dnf repos; install manually"
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm zsh git curl github-cli
elif command -v brew >/dev/null 2>&1; then
    brew install zsh gh
else
    echo "No supported package manager found. Install zsh, git, curl and gh yourself, then re-run." >&2
    exit 1
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

# --- default shell ----------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    log "zsh is already the default shell"
else
    log "Setting zsh as the default shell"
    grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$ZSH_PATH" "$USER" || chsh -s "$ZSH_PATH"
fi

# --- done -------------------------------------------------------------------
log "Done. Remaining manual steps:"
echo "  1. Run 'gh auth login' so the git credential helper works."
echo "  2. If the prompt shows broken symbols, install the MesloLGS NF font in the"
echo "     terminal you are connecting FROM: https://github.com/romkatv/powerlevel10k#fonts"
echo "  3. Log out and back in (or run 'exec zsh') to start using zsh."
