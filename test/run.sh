#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export NVIM_APPNAME="${NVIM_APPNAME:-kickstart.nvim}"

nvim --headless -u init.lua -l test/plugins_spec.lua
nvim --headless -u init.lua -l test/format/markdown_spec.lua
nvim --headless -u init.lua -l test/nx_spec.lua
nvim --headless -u init.lua -l test/facets_spec.lua
nvim --headless -u init.lua -l test/merge_tool_help_spec.lua
nvim --headless -u NONE \
  -c "lua vim.opt.rtp:prepend(vim.fn.getcwd())" \
  -c "lua dofile('test/markdown_xanadu/runner.lua').run()" \
  -c "qa!"
