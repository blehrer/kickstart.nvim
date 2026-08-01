#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
dest="$HOME/Library/Application Support/Cursor/User"

cp "$repo/cursor/settings.json" "$dest/settings.json"
cp "$repo/cursor/keybindings.json" "$dest/keybindings.json"

echo "Synced Cursor settings to $dest"
