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
5. Downloads `.zshrc`, `.p10k.zsh`, `.gitconfig`, `.screenrc`, and `.tmux.conf` from this repo, plus
   `~/.config/kitty/kitty.conf` when kitty is installed. Existing files are backed up first (`.bak.<timestamp>`).
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
the command menu. `:LazyExtras` toggles language support. `<space>gv` opens diffview (side-by-side
review of the whole working tree), `<space>gV` closes it.

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
| `Alt` + `t` / `w` | New window (current directory) / close pane, no prompt |
| `Alt` + `1`..`9` | Go to window N |
| `Alt` + `Shift` + `t` | Rename window |
| `prefix` `Tab` | Last window |
| `prefix` `Enter` | Copy mode (vi keys; `v` select, `y` copy) |
| `prefix` `r` | Reload config |

Dragging with the mouse selects and copies to the system clipboard (OSC 52, so it
also works over ssh in terminals that allow it). On macOS Terminal.app, Alt+arrows
need "Use Option as Meta key" enabled.

## Jupyter notebooks (in the terminal)

`.ipynb` files open in nvim as markdown (jupytext); code blocks run on a Jupyter
kernel through molten.nvim, and plots render inline via image.nvim and the kitty
graphics protocol. Works over ssh, with or without root.

| Key (`<localleader>`) | Action |
|---|---|
| `mi` | Start a kernel for this buffer |
| `rc` | Run the code block under the cursor |
| `rl` / `r` (visual) | Run line / selection |
| `rr` | Re-run the current cell |
| `ro` / `mh` | Open / hide the output window |
| `mx` / `md` | Interrupt kernel / delete cell output |
| `mp` | Play the gif or video path under the cursor |

Try `notebooks/smoke-test.ipynb`: a static plot and an animation rendered to `wave.gif`.

What `setup.sh` provides, all per-user (no root needed):

- **Python host** at `~/.local/share/nvim/python-host` (pynvim, jupyter_client,
  ipykernel, matplotlib, numpy, jupytext), created with [uv](https://github.com/astral-sh/uv),
  which also fetches its own Python. Add packages with
  `uv pip install --python ~/.local/share/nvim/python-host/bin/python <pkg>`.
- **ImageMagick**: from the package manager with root, otherwise a conda-forge
  build installed with micromamba into `~/.local/share/imagemagick`.
- **kitten** (kitty's helper) in `~/.local/bin`, so `kitten icat` works on the server.

Animations: a notebook output cannot play video, so save a gif and view it with
`kitten icat --loop=-1 --hold wave.gif` (also works inside tmux and over ssh), or
press `<localleader>mp` on the filename. mp4 needs `mpv --vo=kitty` and only works
locally, outside tmux.

Requirements on the machine you sit at: a terminal speaking the kitty graphics
protocol (kitty, WezTerm, Ghostty). On the server, tmux must be >= 3.3 for images
to pass through (`allow-passthrough` is set in `tmux.conf`); without tmux, or with
older tmux, run nvim outside it. Nested tmux (local and remote) does not pass images.

## Git diffs (delta)

`git diff`, `git show` and `git log -p` go through [delta](https://github.com/dandavison/delta),
side-by-side by default (`n`/`N` jump between files). On a narrow screen, run
`diffmode inline` for the session (`diffmode side` to go back), or `gdi` for a
single inline `git diff`. Without delta installed, git falls back to plain `less`.

## kitty

Catppuccin mocha, MesloLGS NF 13, block cursor, tabs on top. Installed to
`~/.config/kitty/kitty.conf` only when kitty is present. `cmd+shift+r` reloads it.

| Key | Action |
|---|---|
| `opt+cmd+\|` / `opt+cmd+-` | Split vertically / horizontally (current directory) |
| `cmd+d` / `cmd+shift+d` | Same splits, iTerm style |
| `cmd+alt+` arrows | Move between splits |
| `cmd+1`..`cmd+9` | Go to tab N |
| `cmd+t` / `cmd+w` | New tab / close pane |
| `cmd+enter` | Zoom the current split |
| `cmd+backspace` | Delete the whole line (sends `ctrl+u`) |

It sets `TERM=xterm-256color` so ssh hosts without kitty's terminfo work and the
true-colour override in `tmux.conf` applies. `macos_option_as_alt` is on, so the
Alt+arrow pane bindings in tmux work. Note `opt+cmd+\|` is `alt+super+i` on a
Nordic layout, which is how it is mapped.
