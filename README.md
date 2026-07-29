# nvim.new

Modular Neovim config for 0.12+ using native `vim.pack`, experimental `ui2` + tiny-cmdline (centered `:`), and Snacks as the sole picker.

## Requirements

- Neovim >= 0.12
- Git (for `vim.pack`)
- Nerd Font (recommended)
- Kitty/WezTerm/Ghostty (for `image.nvim` inline images)

## Install

```bash
export NVIM_APPNAME=nvim.new   # or symlink ~/.config/nvim.new → ~/.config/nvim
nvim
```

First launch clones plugins via `vim.pack.add()` into your data directory.

## Layout

```
init.lua              entry: leader keys, ui2, config/*
lua/config/           options, keymaps, autocmds (kickstart port target)
plugin/*.lua          one file per plugin group; each calls vim.pack.add()
snippets/vscode/      nvim-scissors VS Code-style snippets
scripts/              smoke checks
```

## Plugin updates

```vim
:lua vim.pack.update()
```

Lockfile: `nvim-pack-lock.json` (commit for reproducible installs).

## Keymaps (high level)

| Key | Action |
|-----|--------|
| `-` | oil.nvim file tree |
| `\|` | Snacks dashboard |
| `<leader><space>` | Snacks buffers |
| `<leader>sf` | find files |
| `<leader>sg` | live grep |
| `<leader>gs` | neogit |
| `<leader>gm` | codereview MR/PR |
| `<leader>tr` | neotest run |
| `<leader>b` | DAP breakpoint |
| `<leader>.` | Luapad REPL menu |

Set `GITHUB_TOKEN` / `GITLAB_TOKEN` for codereview.nvim.

## LSP (Mason)

`:Mason` installs servers; `:LspInstall <server>` also works.

| Language | Server |
|----------|--------|
| TypeScript/JS | `ts_ls` |
| Java | `jdtls` |
| Kotlin | `kotlin_language_server` |
| HTML | `superhtml` |
| Gradle | `gradle_ls` |
| Python | `pylsp` |
| bash/sh/zsh | `bashls` |
| Lua (incl. Neovim config) | `lua_ls` + lazydev |
| Docker | `dockerls` |

Neovim config Lua uses **lazydev** so `vim.*` and plugin APIs resolve without undeclared-global noise.

Hammerspoon: load the [EmmyLua spoon](https://www.hammerspoon.org/Spoons/EmmyLua.html) once so annotations exist at `~/.hammerspoon/Spoons/EmmyLua.spoon/annotations`; lua_ls then picks up `hs`/`spoon` stubs automatically.

## Verify

```bash
./scripts/check-plugins.sh
```
