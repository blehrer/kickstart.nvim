# nx

Nx monorepo project discovery, target wizard (`<leader>nx`, `<leader>nt`), and project-scoped Trouble filters (`<leader>xp`, `<leader>xP`).

## What goes here

* `workspace.lua` finds `nx.json`, resolves canonical git remote IDs across worktrees, and builds `nx` CLI commands.
* `discover.lua` lists and hydrates Nx projects, caches project lists on disk under `~/.local/share/kickstart.nvim/nx-projects/`, and falls back to `apps/` and `libs/` `project.json` globs when the Nx CLI fails.
* `menu.lua`, `pickers.lua`, `session.lua`, `review.lua`, `execute.lua`, and `run.lua` drive the interactive target runner and review float (`execute.lua` delegates `target == 'e2e'` to `lua/facets/playwright/`).
* `graph.lua` and `trouble.lua` filter Trouble diagnostics to the current buffer's Nx project and its transitive dependents.

## Conventions

* Keep Playwright-specific test/DAP/env logic in `lua/facets/playwright/`, not in `lua/nx/`.
* Never block picker opening on synchronous `nx` CLI calls; read from memory or disk cache first and refresh in the background with `discover.refresh_list`.
* Key disk caches by `workspace.git_remote_id(root)` and `nx.json` mtime so multiple worktrees share cached project lists.
* Pass `env = vim.fn.environ()` to `vim.system` calls so `mise` Node and Java shims stay on `PATH`.
