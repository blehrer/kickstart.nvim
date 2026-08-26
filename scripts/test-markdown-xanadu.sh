#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export NVIM_APPNAME="${NVIM_APPNAME:-kickstart.nvim}"
nvim --headless -u NONE \
  -c "lua vim.opt.rtp:prepend(vim.fn.getcwd())" \
  -c "lua dofile('test/markdown_xanadu/runner.lua').run()" \
  -c "qa!"
