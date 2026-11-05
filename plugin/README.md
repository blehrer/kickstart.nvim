# plugin

Runtime plugin entrypoints autoloaded by Neovim after `init.lua`.

## What goes here

* One file per plugin or tightly related plugin group (`git.lua`, `dap.lua`, `format.lua`, `neotest.lua`, `oil.lua`, `sidekick.lua`, etc.).
* Each file declares its dependencies with `vim.pack.add({ ... })`, runs `.setup()`, and registers the keymaps, user commands, and autocmds for that feature.

## Conventions

* Start every file with `if vim.g.vscode then return end` so terminal plugins stay off in Cursor.
* Use numeric prefixes (`05-tiny-cmdline.lua`, `10-mini-icons.lua`, `15-colorscheme.lua`, `20-treesitter.lua`, `30-snacks.lua`) only when load order across files matters; keep everything else alphabetical.
* When setup logic grows beyond plugin wiring and keymaps, move the implementation into a domain package under `lua/` (`lua/format/`, `lua/nx/`, `lua/facets/`, `lua/merge-tool-help/`, `lua/markdown_xanadu/`) and keep the `plugin/*.lua` file thin.
* Run `./test/run.sh` after adding or removing a plugin, and update `test/plugins_spec.lua` if the module list changes.
