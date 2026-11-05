# config

Core editor settings, keymaps, LSP wiring, and UI helpers loaded from `init.lua` and `plugin/*.lua`.

## What goes here

* `options.lua`, `keymaps.lua`, `autocmds.lua`, `ui2.lua`, `exrc.lua`, and `statusline.lua` run unconditionally during terminal startup from `init.lua`.
* `lsp.lua`, `lsp_panels.lua`, `hover.lua`, and `lsp_symbol_sources.lua` configure `vim.lsp.config`, `mason-lspconfig`, the `<A-1>` doc/symbol splits, and workspace symbol server selection (`<leader>sl`, `<leader>sL`).
* `code_actions/` merges LSP code actions with local Treesitter providers (`java_sql.lua`) behind `<leader>ca`.
* `ui_toggle.lua`, `gutter.lua`, `notifications.lua`, `gitbrowse.lua`, `gf.lua`, `dial.lua`, and `terminal_alt.lua` hold small focused helpers called by plugin files.
* `cursor.lua` is the early-return profile when `init.lua` runs under `vim.g.vscode`.

## Conventions

* Do not call `vim.pack.add` inside `lua/config/`; plugin declarations belong in `plugin/*.lua`.
* Modules required by Cursor (`keymaps.lua`, `dial.lua`) must guard terminal-only bindings with `if not vim.g.vscode`.
* Use `require('config.terminal_alt').set` when binding `<A-digit>` keys so macOS US Option characters (`¡`, `™`, etc.) are mapped alongside Meta.
