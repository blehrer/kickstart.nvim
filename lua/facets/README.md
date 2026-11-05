# facets

Repo-level project detection anchored at `git rev-parse --show-toplevel` (`plugin/facets.lua`).

## What goes here

* `anchor.lua` resolves the git root and collects stack manifests (`package.json`, `build.gradle.kts`, `pyproject.toml`, `go.mod`, `Cargo.toml`).
* `registry.lua` loads facet definitions from `FACET_MODULES` and caches active facets by repo remote and manifest mtime.
* `<stack>/<name>.lua` (`typescript/eslint.lua`, `kotlin/jvm.lua`, `playwright/e2e.lua`) defines a facet: `id`, `requires`, `detect(ctx)`, and optional `lsp`, `trouble`, or `conform_formatters` hooks.
* `<tool>/run.lua` (`eslint/run.lua`, `tsc/run.lua`, `knip/run.lua`) runs repo-wide checks asynchronously and returns `trouble.Item[]`.
* `trouble.lua` and `trouble_jump.lua` register the `facets_*` Trouble sources and modes (`<leader>xe`, `<leader>xE`, `<leader>xT`).

## Conventions

* Facets describe tooling at the git root. Sub-project scoping inside a monorepo belongs in `lua/nx/`.
* Read JSON files through `require('nx.workspace').read_json(path)` rather than adding local file readers.
* Write large CLI output to a temp file (`vim.fn.tempname()`) before decoding; `vim.system` stdout can truncate large reports.
* `:FacetsInfo` prints the resolved root, stacks, and active facet IDs for the current buffer (`:FacetsInfo!` uses `cwd`).
