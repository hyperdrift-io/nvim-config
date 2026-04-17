#!/usr/bin/env bash
# Smoke tests for macOS — run after ./install.sh --both --yes
set -euo pipefail

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; ((PASS++)); }
fail() { echo "  ✗ $*"; ((FAIL++)); }

assert_cmd()    { command -v "$1" &>/dev/null && ok "$1 in PATH" || fail "$1 not found"; }
assert_symlink() { [[ -L "$1" ]] && ok "symlink: $1" || fail "not a symlink: $1"; }
assert_file()   { [[ -f "$1" ]] && ok "exists: $1"  || fail "missing: $1"; }

echo ""
echo "── nvim-config smoke tests (macOS) ──────────────────────────────────"

echo ""
echo "Binaries"
assert_cmd vim
assert_cmd nvim

echo ""
echo "Vim symlinks"
assert_symlink "$HOME/.vimrc"
assert_symlink "$HOME/.vimrc.maps"
assert_symlink "$HOME/.vimrc.conf.base"
assert_symlink "$HOME/.vimrc.plugin"

echo ""
echo "Neovim symlinks"
assert_symlink "$HOME/.config/nvim/init.lua"
assert_symlink "$HOME/.config/nvim/lua/plugins/init.lua"
assert_symlink "$HOME/.config/nvim/lua/sessions/picker.lua"

echo ""
echo "Plugin managers"
assert_file "$HOME/.vim/autoload/plug.vim"
assert_file "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim/lua/lazy/init.lua"

echo ""
echo "Neovim config loads"
if nvim --headless -c 'lua require("lazy")' -c 'qa' 2>/dev/null; then
  ok "nvim: lazy.nvim loads cleanly"
else
  fail "nvim: lazy.nvim load failed"
fi

echo ""
echo "Telescope dependencies"
assert_cmd rg
assert_cmd fd

echo ""
echo "─────────────────────────────────────────────────────────────────────"
echo "  Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]] && echo "  All tests passed." && exit 0
echo "  Some tests failed." && exit 1
