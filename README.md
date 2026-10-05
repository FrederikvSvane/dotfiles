# dotfiles

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/FrederikvSvane/dotfiles/main/setup.sh | bash
```

The script:

1. Installs zsh, git, curl, GNU Screen, tmux, and gh (apt, dnf, pacman, or brew).
   Without root (not root and no sudo), it instead installs zsh
   ([zsh-bin](https://github.com/romkatv/zsh-bin)) and gh into `~/.local`. git
   and curl must already be present, and Screen and tmux are skipped if missing.
2. Installs oh-my-zsh.
3. Installs powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting.
4. Installs Neovim (>= 0.11) plus ripgrep, fd, lazygit and delta for LazyVim and git. With root
   it uses the package manager and `/opt/nvim`; without root everything goes to
   `~/.local`.
5. Downloads `.zshrc`, `.p10k.zsh`, `.gitconfig`, and `.screenrc`, and `.tmux.conf` from this repo. Existing files are backed up first (`.bak.<timestamp>`).
6. Installs the LazyVim + Catppuccin config from `nvim/` to `~/.config/nvim`
   and restores the plugins pinned in `lazy-lock.json`.
7. Sets zsh as the default shell. Without root, if `chsh` isn't possible, it
   adds a snippet to `~/.bashrc` that starts zsh instead.

Safe to re-run: anything already installed is skipped, and a config file is only
backed up and replaced when it differs from the repo's version.

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

## tmux

Mouse and trackpad scrolling work out of the box (scroll up enters copy mode),
with 50k lines of history, true colour and Catppuccin mocha colours. The prefix
is still `Ctrl-b`.

| Key | Action |
|---|---|
| `prefix` `\|` / `-` | Split right / down (keeps current directory) |
| `Alt` + arrows | Move between panes, no prefix |
| `Shift` + left/right | Previous / next window, no prefix |
| `prefix` `H J K L` | Resize panes |
| `prefix` `Enter` | Copy mode (vi keys; `v` select, `y` copy) |
| `prefix` `r` | Reload config |

Dragging with the mouse selects and copies to the system clipboard (OSC 52, so it
also works over ssh in terminals that allow it). On macOS Terminal.app, Alt+arrows
need "Use Option as Meta key" enabled.

## Git diffs (delta)

`git diff`, `git show` and `git log -p` go through [delta](https://github.com/dandavison/delta),
side-by-side by default (`n`/`N` jump between files). On a narrow screen, run
`diffmode inline` for the session (`diffmode side` to go back), or `gdi` for a
single inline `git diff`. Without delta installed, git falls back to plain `less`.
