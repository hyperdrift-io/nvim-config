#!/usr/bin/env bash
# Linux smoke tests — designed to run inside Docker
# Usage: docker run --rm -v $(pwd):/repo ubuntu:24.04 bash /repo/test/test-install-linux.sh
set -euo pipefail

PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; ((PASS++)); }
fail() { echo "  ✗ $*"; ((FAIL++)); }

assert_cmd()     { command -v "$1" &>/dev/null && ok "$1 in PATH" || fail "$1 not found"; }
assert_symlink() { [[ -L "$1" ]] && ok "symlink: $1" || fail "not a symlink: $1"; }
assert_file()    { [[ -f "$1" ]] && ok "exists: $1"  || fail "missing: $1"; }

echo ""
echo "── nvim-config smoke tests (Linux) ─────────────────────────────────"

# Install prerequisites silently
if command -v apt-get &>/dev/null; then
  apt-get update -qq && apt-get install -y -qq curl git sudo 2>/dev/null
elif command -v apk &>/dev/null; then
  apk add --no-cache curl git sudo 2>/dev/null
fi

# Run the installer in non-interactive, nvim-only mode
bash /repo/install.sh --nvim --yes 2>&1

echo ""
echo "Binaries"
assert_cmd nvim

echo ""
echo "Neovim symlinks"
assert_symlink "$HOME/.config/nvim/init.lua"
assert_symlink "$HOME/.config/nvim/lua/plugins/init.lua"

echo ""
echo "lazy.nvim bootstrap"
assert_file "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim/lua/lazy/init.lua"

echo ""
echo "Neovim config loads"
if nvim --headless -c 'lua require("lazy")' -c 'qa' 2>/dev/null; then
  ok "nvim: lazy.nvim loads cleanly"
else
  fail "nvim: lazy.nvim load failed"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────"
echo "  Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]] && echo "  All tests passed." && exit 0
echo "  Some tests failed." && exit 1
