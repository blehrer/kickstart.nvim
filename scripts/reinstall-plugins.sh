#!/usr/bin/env bash
# ponytail: drop lazy.nvim dir + vim.pack tree, then bootstrap from nvim-pack-lock.json
set -euo pipefail

export NVIM_APPNAME="${NVIM_APPNAME:-kickstart.nvim}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/$NVIM_APPNAME"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/$NVIM_APPNAME"

for dir in lazy site/pack; do
  if [[ -e "$DATA/$dir" ]]; then
    echo "Removing $DATA/$dir"
    rm -rf "$DATA/$dir"
  fi
done

# Leftover from lazy/telescope era; harmless but confusing once pack is canonical.
rm -f "$DATA/telescope_history" "$DATA/rplugin.vim"

echo "Reinstalling plugins into $DATA/site/pack (from $CONFIG)..."
nvim --headless "+lua vim.pack.update()" +qa 2>&1

"$CONFIG/scripts/check-plugins.sh"
