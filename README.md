# nvim-config

**Battle-tested vim/neovim setup. One command. Any machine.**

A cross-platform installer for a production-grade vim and neovim configuration —
session management, fuzzy finding, LSP-ready, GitHub Copilot, and full vim/nvim
key-binding parity. Built for developers who live in the terminal.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yannvr/nvim-config/main/install.sh)
```

---

## What you get

### Neovim

| Feature | Plugin |
|---|---|
| Session picker with favourites, rename, delete | `persisted.nvim` + custom telescope picker |
| Fuzzy file/buffer/grep search | `telescope.nvim` + `fzf.vim` |
| Completion + snippets | `nvim-cmp` + `LuaSnip` |
| GitHub Copilot | `copilot.vim` |
| Git UI | `vim-fugitive` + `neogit` + `diffview` |
| Status bar | `vim-airline` |
| Undo history tree | `vim-mundo` |
| Auto-pairs, surround, easy-align | tpope suite |

### Vim

| Feature | Mechanism |
|---|---|
| Session management | Built-in vimscript (`SessionOpen`, `SessionSave`, `SessionDelete`) |
| Plugin management | `vim-plug` |
| Completion | `nvim-cmp` equivalent via `neocomplete` |
| Fuzzy finding | `fzf.vim` |

### Key bindings (identical in vim and nvim)

| Key | Action |
|---|---|
| `\so` | Open session picker |
| `\ss` | Save current session |
| `\sd` | Delete current session |
| `\sq` | Save session and quit |
| `\f` | Fuzzy file search |
| `\g` | Live grep |
| `\b` | Buffer explorer |
| `jj` | Exit insert mode |

---

## Install options

```bash
# Neovim only (default)
./install.sh

# Vim only
./install.sh --vim

# Both vim and neovim
./install.sh --both

# Server/remote mode — skips GUI plugins, Copilot, fonts
./install.sh --remote

# Non-interactive (CI, scripted setup)
./install.sh --yes

# Preview only — nothing is written
./install.sh --dry-run
```

---

## Supported platforms

| OS | Vim | Neovim |
|---|---|---|
| macOS (Homebrew) | ✓ | ✓ |
| Ubuntu / Debian | ✓ | ✓ (snap if available) |
| Fedora / RHEL / Rocky | ✓ | ✓ |
| Alpine Linux | ✓ | ✓ |
| Arch / Manjaro | ✓ | ✓ |

---

## Session management

Opening `nvim` without arguments launches a **telescope session picker** automatically:

- `<CR>` — load session
- `s` — save / update selected session
- `S` — save as new name
- `r` — rename session
- `d` — delete session (with confirmation)
- `f` — toggle favourite (★ pinned to top)
- `R` — refresh list

Sessions are sorted: **favourites first, then most recently modified.**

---

## Remote / sysadmin use

The `--remote` flag is optimised for bastion hosts and remote servers:
- Skips Copilot (requires internet + auth)
- Skips GUI-dependent plugins (Powerline fonts)
- Minimal plugin set — fast startup

```bash
# One-liner for a fresh server
bash <(curl -fsSL https://raw.githubusercontent.com/yannvr/nvim-config/main/install.sh) --remote --yes
```

---

## dotfiles integration

If you use [yannvr/dotfiles](https://github.com/yannvr/dotfiles), `nvim-config` is included as a submodule and wired into the main installer automatically.

```bash
git clone --recurse-submodules https://github.com/yannvr/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

---

## Structure

```
nvim-config/
├── install.sh          # cross-platform installer
├── test/
│   ├── test-install-macos.sh
│   └── test-install-linux.sh
├── vim/                # vim config files (symlinked from dotfiles)
│   ├── .vimrc
│   ├── .vimrc.conf.base
│   ├── .vimrc.conf
│   ├── .vimrc.maps
│   ├── .vimrc.plugin
│   └── .vimrc.filetypes
└── nvim/               # neovim config (symlinked from dotfiles)
    ├── init.lua
    └── lua/
        ├── plugins/init.lua
        └── sessions/picker.lua
```

---

## Requirements

- `git` ≥ 2.20
- `curl` (for vim-plug bootstrap)
- macOS: [Homebrew](https://brew.sh)
- Linux: `apt`, `dnf`, `apk`, or `pacman`

---

*Part of the [Hyperdrift](https://hyperdrift.io) toolchain.*
*Installer built with [typerx](https://github.com/yannvr/typerx) — Python scripting on steroids.*
