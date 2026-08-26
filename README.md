# dotfiles

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/FrederikvSvane/dotfiles/main/setup.sh | bash
```

The script:

1. Installs zsh, git, curl, and gh (apt, dnf, pacman, or brew).
2. Installs oh-my-zsh.
3. Installs powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting.
4. Downloads `.zshrc`, `.p10k.zsh`, and `.gitconfig` from this repo. Existing files are backed up first (`.bak.<timestamp>`).
5. Sets zsh as the default shell.

Safe to re-run.

## After setup

- Run `gh auth login`.
- Powerlevel10k needs the [MesloLGS NF font](https://github.com/romkatv/powerlevel10k#fonts). Install it in the terminal you connect *from*, not on the remote machine.
- Run `exec zsh` or log out and back in.
