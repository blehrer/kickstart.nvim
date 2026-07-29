#!/usr/bin/env bash
# ponytail: smallest check that plugin modules resolve after vim.pack bootstrap
set -euo pipefail

export NVIM_APPNAME="${NVIM_APPNAME:-nvim.new}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/$NVIM_APPNAME"

nvim --headless "+luafile $CONFIG/scripts/check-plugins.lua" +qa 2>&1
