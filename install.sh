#!/usr/bin/env bash
# =============================================================================
# nvim-config installer — cross-platform vim/neovim setup
# https://github.com/yannvr/nvim-config
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/yannvr/nvim-config/main/install.sh)
#   ./install.sh --vim          # vim only
#   ./install.sh --nvim         # neovim only (default)
#   ./install.sh --both         # vim + neovim
#   ./install.sh --remote       # server mode (no GUI plugins, no Copilot)
#   ./install.sh --yes          # non-interactive
#   ./install.sh --dry-run      # preview only
# =============================================================================
set -euo pipefail

REPO_URL="https://github.com/hyperdrift-io/nvim-config"
RAW_URL="https://raw.githubusercontent.com/hyperdrift-io/nvim-config/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# ── colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${BLUE}ℹ  ${*}${NC}"; }
success() { echo -e "${GREEN}✓  ${*}${NC}"; }
warn()    { echo -e "${YELLOW}⚠  ${*}${NC}"; }
error()   { echo -e "${RED}✗  ${*}${NC}" >&2; }
step()    { echo -e "\n${CYAN}▶  ${*}${NC}"; }
die()     { error "$*"; exit 1; }

# ── flags ─────────────────────────────────────────────────────────────────────
INSTALL_VIM=false
INSTALL_NVIM=false
REMOTE=false
YES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --vim)       INSTALL_VIM=true ;;
    --nvim)      INSTALL_NVIM=true ;;
    --both)      INSTALL_VIM=true; INSTALL_NVIM=true ;;
    --remote)    REMOTE=true ;;
    --yes|-y)    YES=true ;;
    --dry-run)   DRY_RUN=true ;;
    --help|-h)   show_help; exit 0 ;;
    *)           die "Unknown flag: $1. Use --help." ;;
  esac
  shift
done

show_help() {
  cat <<EOF
nvim-config installer

  --vim        Install vim configuration only
  --nvim       Install neovim configuration only  (default if neither specified)
  --both       Install both vim and neovim
  --remote     Server mode: skip GUI plugins, Copilot, Powerline fonts
  --yes / -y   Non-interactive: accept all defaults
  --dry-run    Show what would be done, make no changes

EOF
}

# Default: nvim only
if [[ "$INSTALL_VIM" == false && "$INSTALL_NVIM" == false ]]; then
  INSTALL_NVIM=true
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] $*"
  else
    "$@"
  fi
}

prompt() {
  local question="$1" default="${2:-n}"
  [[ "$YES" == true ]]     && { echo "$default"; return; }
  [[ "$DRY_RUN" == true ]] && { echo "n"; return; }
  local answer
  read -rp "❓ $question [$default]: " answer
  echo "${answer:-$default}"
}

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"
DISTRO=""
if [[ "$OS" == "Linux" ]] && [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  DISTRO="$(. /etc/os-release && echo "${ID}")"
fi

install_pkg() {
  local pkg="$1"
  case "$OS" in
    Darwin)
      command -v brew &>/dev/null || die "Homebrew not found. Install: https://brew.sh"
      run brew install "$pkg"
      ;;
    Linux)
      case "$DISTRO" in
        ubuntu|debian) run sudo apt-get install -y "$pkg" ;;
        fedora|rhel|centos|rocky|alma) run sudo dnf install -y "$pkg" ;;
        alpine) run sudo apk add --no-cache "$pkg" ;;
        arch|manjaro) run sudo pacman -Sy --noconfirm "$pkg" ;;
        *) die "Unsupported distro: ${DISTRO}. Install $pkg manually." ;;
      esac
      ;;
    *) die "Unsupported OS: $OS" ;;
  esac
}

# ── source directory ──────────────────────────────────────────────────────────
# Works whether run from a clone or piped via curl
resolve_config_dir() {
  if [[ -d "$SCRIPT_DIR/nvim" ]]; then
    echo "$SCRIPT_DIR"
  else
    # Fetched via curl — clone the repo
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    info "Cloning nvim-config into $tmp_dir ..."
    run git clone --depth=1 "$REPO_URL" "$tmp_dir/nvim-config"
    echo "$tmp_dir/nvim-config"
  fi
}

# ── vim install ───────────────────────────────────────────────────────────────
install_vim() {
  step "Installing vim configuration"

  if ! command -v vim &>/dev/null; then
    info "vim not found — installing..."
    install_pkg vim
  else
    success "vim $(vim --version | head -1 | awk '{print $5}') already installed"
  fi

  local src="$1/vim"

  # Symlink vimrc files
  for f in .vimrc .vimrc.conf.base .vimrc.conf .vimrc.maps .vimrc.plugin .vimrc.filetypes; do
    local target="$HOME/$f"
    local source="$src/$f"
    if [[ ! -f "$source" ]]; then
      warn "Source not found: $source — skipping $f"
      continue
    fi
    if [[ -e "$target" && ! -L "$target" ]]; then
      run mv "$target" "${target}.bak.$(date +%s)"
      info "Backed up existing $f"
    fi
    run ln -sf "$source" "$target"
    success "Linked $f"
  done

  # Install vim-plug
  local plug_path="$HOME/.vim/autoload/plug.vim"
  if [[ ! -f "$plug_path" ]]; then
    info "Installing vim-plug..."
    run curl -fLo "$plug_path" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    success "vim-plug installed"
  else
    success "vim-plug already present"
  fi

  # Install plugins headlessly
  if [[ "$DRY_RUN" == false ]]; then
    info "Installing vim plugins (headless)..."
    vim +PlugInstall +qall 2>/dev/null || warn "Plugin install may need manual review — open vim and run :PlugInstall"
    success "Vim plugins installed"
  else
    info "[dry-run] Would run: vim +PlugInstall +qall"
  fi
}

# ── nvim install ──────────────────────────────────────────────────────────────
install_nvim() {
  step "Installing neovim configuration"

  if ! command -v nvim &>/dev/null; then
    info "neovim not found — installing..."
    case "$OS" in
      Darwin) install_pkg neovim ;;
      Linux)
        case "$DISTRO" in
          ubuntu|debian)
            # apt neovim is often outdated — prefer snap or AppImage for v0.9+
            if command -v snap &>/dev/null; then
              run sudo snap install nvim --classic
            else
              run sudo apt-get install -y neovim
            fi
            ;;
          *) install_pkg neovim ;;
        esac
        ;;
    esac
  else
    success "nvim $(nvim --version | head -1) already installed"
  fi

  local src="$1/nvim"
  local nvim_cfg="$HOME/.config/nvim"

  run mkdir -p "$nvim_cfg/lua/plugins" "$nvim_cfg/lua/sessions"

  # Symlink init.lua
  if [[ -e "$nvim_cfg/init.lua" && ! -L "$nvim_cfg/init.lua" ]]; then
    run mv "$nvim_cfg/init.lua" "$nvim_cfg/init.lua.bak.$(date +%s)"
    info "Backed up existing init.lua"
  fi
  run ln -sf "$src/init.lua" "$nvim_cfg/init.lua"
  success "Linked init.lua"

  # Symlink lua modules
  for mod in plugins/init.lua sessions/picker.lua; do
    local target="$nvim_cfg/lua/$mod"
    local source="$src/lua/$mod"
    if [[ ! -f "$source" ]]; then
      warn "Source not found: $source — skipping $mod"
      continue
    fi
    run mkdir -p "$(dirname "$target")"
    [[ -e "$target" && ! -L "$target" ]] && run mv "$target" "${target}.bak.$(date +%s)"
    run ln -sf "$source" "$target"
    success "Linked lua/$mod"
  done

  # Bootstrap lazy.nvim
  local lazy_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
  if [[ ! -d "$lazy_path" ]]; then
    info "Bootstrapping lazy.nvim..."
    run git clone --filter=blob:none --branch=stable \
      https://github.com/folke/lazy.nvim.git "$lazy_path"
    success "lazy.nvim installed"
  else
    success "lazy.nvim already present"
  fi

  # Install plugins headlessly
  if [[ "$DRY_RUN" == false ]]; then
    info "Installing nvim plugins (headless — may take a minute)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null \
      || warn "Plugin sync may need manual review — open nvim and run :Lazy sync"
    success "Neovim plugins installed"
  else
    info "[dry-run] Would run: nvim --headless '+Lazy! sync' +qa"
  fi

  # Install neovim npm package for node provider
  if command -v npm &>/dev/null; then
    run npm install -g neovim &>/dev/null && success "neovim npm package installed" \
      || warn "Could not install neovim npm package — run: npm install -g neovim"
  fi

  # Install ripgrep + fd (telescope live-grep dependencies)
  for tool in ripgrep fd; do
    local cmd="${tool/ripgrep/rg}"
    [[ "$tool" == "fd" ]] && cmd="fd"
    if ! command -v "$cmd" &>/dev/null; then
      info "Installing $tool (telescope dependency)..."
      install_pkg "$tool" || warn "Could not install $tool — install manually"
    fi
  done
}

# ── smoke test ────────────────────────────────────────────────────────────────
smoke_test() {
  step "Running smoke tests"
  local all_ok=true

  if [[ "$INSTALL_VIM" == true ]]; then
    if command -v vim &>/dev/null && [[ -L "$HOME/.vimrc" ]]; then
      success "vim: binary + .vimrc symlink OK"
    else
      warn "vim: something looks off — check manually"
      all_ok=false
    fi
  fi

  if [[ "$INSTALL_NVIM" == true ]]; then
    if command -v nvim &>/dev/null && [[ -L "$HOME/.config/nvim/init.lua" ]]; then
      success "nvim: binary + init.lua symlink OK"
      if nvim --headless -c 'lua require("lazy")' -c 'qa' 2>/dev/null; then
        success "nvim: lazy.nvim loads cleanly"
      else
        warn "nvim: lazy.nvim check failed — open nvim to diagnose"
        all_ok=false
      fi
    else
      warn "nvim: something looks off — check manually"
      all_ok=false
    fi
  fi

  [[ "$all_ok" == true ]] && success "All smoke tests passed" || warn "Some checks failed — see above"
}

# ── banner ────────────────────────────────────────────────────────────────────
echo ""
echo "  ███╗   ██╗██╗   ██╗██╗███╗   ███╗      ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ "
echo "  ████╗  ██║██║   ██║██║████╗ ████║     ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ "
echo "  ██╔██╗ ██║██║   ██║██║██╔████╔██║     ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗"
echo "  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║     ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║"
echo "  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║     ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝"
echo "  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ "
echo ""
echo "  Battle-tested vim/neovim setup. One command. Any machine."
  echo "  https://github.com/hyperdrift-io/nvim-config"
echo ""

# ── main ──────────────────────────────────────────────────────────────────────
CONFIG_DIR="$(resolve_config_dir)"

[[ "$INSTALL_VIM" == true ]]  && install_vim  "$CONFIG_DIR"
[[ "$INSTALL_NVIM" == true ]] && install_nvim "$CONFIG_DIR"

smoke_test

echo ""
success "Done! Start editing at the speed of thought."
echo ""
if [[ "$INSTALL_NVIM" == true ]]; then
  echo "  Open nvim → session picker loads automatically on bare launch"
  echo "  \\so  open session picker    \\ss  save session"
  echo "  \\so  open session picker    \\sd  delete session"
  echo "  <leader>f  fuzzy find files  <leader>g  live grep"
  echo ""
fi
