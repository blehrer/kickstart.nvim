# cursor

Cursor IDE settings, keybindings, and the slim `vscode-neovim` bootstrap.

## What goes here

* `settings.json` and `keybindings.json` are the versioned Cursor user config files; `sync.sh` copies them to `~/Library/Application Support/Cursor/User/`.
* `nvim-cursor.sh` wraps `/opt/homebrew/bin/nvim` with `unset NVIM_APPNAME` so `plugin/*.lua` does not autoload inside Cursor.
* `nvim-init.lua` is the `vscode-neovim` init file: it loads `config.keymaps`, `config.dial`, and `format.save_toggle`.

## Conventions

* Use `vscode-neovim` for modal editing and let Cursor own pickers, git, formatting, and test runners via `keybindings.json` (`<leader>sf`, `<leader>sg`, `<leader>gs`, `<leader>ff`, `<leader>fF`, `<leader>nx`, `<leader>tr`).
* Run `./cursor/sync.sh` after editing `settings.json` or `keybindings.json`.
