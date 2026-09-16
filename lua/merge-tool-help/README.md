# merge-tool-help

A local Neovim plugin for [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) that adds a tmux `display-panes`-style help overlay when resolving git merge conflicts with `nvimdiff`.

## Installation

This plugin lives inside your kickstart config:

```
~/.config/kickstart.nvim/
├── plugin/merge-tool-help.lua   # calls require('merge-tool-help').setup()
└── lua/merge-tool-help/         # module source (this README)
```

Remote plugins use **`vim.pack`**; this feature is a local module on the same runtimepath as the rest of the config.

## Git mergetool setup

```ini
[merge]
    tool = nvimdiff

[mergetool "nvimdiff"]
    cmd = nvim -d -f "$LOCAL" "$BASE" "$REMOTE" "$MERGED"
```

See `git help mergetool` for layout options (`mergetool.nvimdiff.layout`).

## Usage

| Key / Command | Action |
|---------------|--------|
| `F1` or `:MergeToolHelp` | Toggle help panel |
| `1`–`9` | Preview numbered pane (highlight in diagram) |
| `<Enter>` | Go to selected pane and close panel |
| `o` | Toggle pane view / options view |
| `q` / `<Esc>` | Close panel |
| `:MergeToolRecompute` | Recompute merge into MERGED (with confirms) |

### Pane view

Shows a box diagram of your merge layout with the active pane number highlighted. Below it: buffer role, name, whether to edit, and why.

### Options view (`o`)

**Tier 1 — diff display (safe, instant)**

| Key | Toggles |
|-----|---------|
| `i` | Ignore whitespace: off → iwhite → iwhiteall → iwhiteeol |
| `h` | Indent heuristic |
| `a` | Diff algorithm: myers → minimal → patience → histogram |

**Tier 2 — merge recompute (rewrites MERGED)**

| Key | Toggles |
|-----|---------|
| `d` | Conflict style: default → diff3 → zdiff3 |
| `f` | Favor: none → ours → theirs → union |
| `m` | Merge algorithm |
| `r` | Recompute now |

Recompute runs `git merge-file -p LOCAL BASE REMOTE` and writes stdout to `$MERGED`.

**Safety prompts before recompute:**

1. If MERGED contains conflict markers (`<<<<<<<`, etc.) — asks to discard them first
2. If MERGED buffer is modified — asks to overwrite resolution progress

Whitespace ignoring applies to **diff display only** (`diffopt`). `git merge-file` does not support `-Xignore-space-change`.

## Open this repo in Cursor

Open `~/.config/kickstart.nvim` as your workspace folder in the Cursor sidebar to work on this plugin alongside your config.
