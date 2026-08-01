#!/usr/bin/env bash
# ponytail: unset NVIM_APPNAME so kickstart.nvim/plugin/*.lua does not autoload in Cursor embed
unset NVIM_APPNAME
exec /opt/homebrew/bin/nvim "$@"
