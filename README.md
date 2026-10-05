# dotfiles

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/FrederikvSvane/dotfiles/main/setup.sh | bash
```

The script:

1. Installs zsh, git, curl, GNU Screen, and gh (apt, dnf, pacman, or brew).
   Without root (not root and no sudo), it instead installs zsh
   ([zsh-bin](https://github.com/romkatv/zsh-bin)) and gh into `~/.local`. git
   and curl must already be present, and Screen is skipped if missing.
2. Installs oh-my-zsh.
3. Installs powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting.
4. Installs Neovim (>= 0.11) plus ripgrep, fd and lazygit for LazyVim. With root
   it uses the package manager and `/opt/nvim`; without root everything goes to
   `~/.local`.
5. Downloads `.zshrc`, `.p10k.zsh`, `.gitconfig`, and `.screenrc` from this repo. Existing files are backed up first (`.bak.<timestamp>`).
6. Installs the LazyVim + Catppuccin config from `nvim/` to `~/.config/nvim`
   and restores the plugins pinned in `lazy-lock.json`.
7. Sets zsh as the default shell. Without root, if `chsh` isn't possible, it
   adds a snippet to `~/.bashrc` that starts zsh instead.

Safe to re-run.

GNU Screen automatically reads `~/.screenrc` when a new session starts. The
included configuration keeps 10,000 lines of history and enables native
terminal scrolling for xterm-compatible terminals.

## After setup

- Run `gh auth login`.
- Powerlevel10k needs the [MesloLGS NF font](https://github.com/romkatv/powerlevel10k#fonts). Install it in the terminal you connect *from*, not on the remote machine.
- Run `exec zsh` or log out and back in.

## Neovim

LazyVim with Catppuccin (mocha). Arrow keys and mouse work; press `<space>` for
the command menu. `:LazyExtras` toggles language support.

Edit root-owned files with `sudoedit <file>` (alias `svim`), which runs your own
nvim config and only escalates the save. Plain `sudo nvim` may use root's empty
config depending on the system's `HOME` handling.
