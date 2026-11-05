# nx

Nx monorepo project discovery, run/debug wizard (`<leader>nx`, `<leader>nt`), Playwright neotest/DAP integration, and project-scoped Trouble filters (`<leader>xp`, `<leader>xP`).

## What goes here

* `workspace.lua` finds `nx.json`, resolves canonical git remote IDs across worktrees, reads JSON files, and builds `nx` CLI commands.
* `discover.lua` lists and hydrates Nx projects, caches project lists on disk under `~/.local/share/kickstart.nvim/nx-projects/`, and falls back to `apps/` and `libs/` `project.json` globs when the Nx CLI fails.
* `menu.lua`, `pickers.lua`, `session.lua`, `review.lua`, `execute.lua`, and `run.lua` drive the interactive target runner and review float.
* `playwright.lua` and `playwright_cli.lua` wire `neotest-playwright`, `.env.<configuration>` loading, CLI flag completion, and `pwa-node` DAP launches.
* `graph.lua` and `trouble.lua` filter Trouble diagnostics to the current buffer's Nx project and its transitive dependents.

## Conventions

* Never block picker opening on synchronous `nx` CLI calls; read from memory or disk cache first and refresh in the background with `discover.refresh_list`.
* Key disk caches by `workspace.git_remote_id(root)` and `nx.json` mtime so multiple worktrees share cached project lists.
* Pass `env = vim.fn.environ()` to `vim.system` calls so `mise` Node and Java shims stay on `PATH`.
