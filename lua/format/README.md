# format

Buffer formatting helpers backing `conform.nvim` in `plugin/format.lua`.

## What goes here

* `policy.lua` reads root `package.json` `lint-staged` rules and `.prettierignore`, matching repo-relative paths via Node `micromatch` (with a Lua glob fallback).
* `deference.lua` builds the `project_ci` formatter (`nx format:write` and `lint-fix`) when `lint-staged` covers a file, and skips auto-formatting when a file is outside project policy.
* `hunks.lua` computes a `conform` range covering modified `gitsigns` hunks for `<leader>ff` and format-on-save.
* `markdown.lua` wraps Prettier for markdown (`gq` and `conform`), guarding reference links and skipping tables and code fences.
* `save_toggle.lua` toggles `vim.g.format_on_save` and `vim.g.editorconfig` together (`<leader>uf`), persisting state to `state/format-on-save` and syncing with Cursor settings when `vim.g.vscode` is set.

## Conventions

* All skip and `project_ci` routing goes through `format_opts(bufnr)` in `plugin/format.lua`.
* Keep `save_toggle.lua` free of terminal-only plugin dependencies at load time so `cursor/nvim-init.lua` can require it directly.
* Run `NVIM_APPNAME=kickstart.nvim nvim --headless -u init.lua -l scripts/test-format-markdown.lua` after changing `markdown.lua`.
