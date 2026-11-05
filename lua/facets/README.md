# facets

Repo-level project detection and stack tooling anchored at `git rev-parse --show-toplevel` (`plugin/facets.lua`).

## What goes here

* `anchor.lua` resolves the git root, reads JSON files (`anchor.read_json`), and collects stack manifests (`package.json`, `build.gradle.kts`, `pyproject.toml`, `go.mod`, `Cargo.toml`).
* `registry.lua` loads facet modules from `FACET_MODULES` and caches active facets by repo remote and manifest mtime.
* `eslint.lua`, `tsc.lua`, and `knip.lua` each define a facet (`id`, `requires`, `detect(ctx)`, `trouble`, optional `lsp` and `dap`) alongside its async CLI runner and output parser (`tsc.lua` also wires `pwa-node` / `node` DAP for TS/JS).
* `kotlin.lua` detects Gradle/Kotlin repos, enables `kotlin_lsp`, wires `ktlint`/`ktfmt` for `conform.nvim`, and configures `kotlin-debug-adapter` (`dap(ctx)`).
* `python.lua` (`python.env`) and `go.lua` (`go.mod`) detect Python and Go repos, enable their LSPs (`ruff` + `basedpyright`, `gopls`), and configure `debugpy` and `delve` DAP adapters + launch/attach templates (`dap(ctx)`).
* `lsp_apply.lua` applies both `def.lsp(ctx)` and `def.dap(ctx)` when entering a repo (and registers baseline DAP adapters at startup via `setup_dap_defaults()`).
* `playwright/` (`init.lua`, `cli.lua`) owns Playwright detection, `neotest-playwright` adapter wiring, `.env.<configuration>` loading (`<leader>te`), `playwright test --help` flag completion/picker (`<leader>tP`), and `pwa-node` DAP (`<leader>td`).
* `trouble.lua` and `trouble_jump.lua` build and register the `facets_*` Trouble sources and modes (`<leader>xe`, `<leader>xE`, `<leader>xT`) from a single source factory.

## Conventions

* Facets own repo/stack tooling (Trouble checks, Neotest adapters, DAP, LSP enable, Conform formatters). Monorepo project scoping and target wizards live in `lua/nx/`.
* Read JSON files through `require('facets.anchor').read_json(path)`.
* Write large CLI output to a temp file (`vim.fn.tempname()`) before decoding; `vim.system` stdout can truncate large reports.
* `:FacetsInfo` prints the resolved root, stacks, and active facet IDs for the current buffer (`:FacetsInfo!` uses `cwd`).
* Run `./test/run.sh` (which includes `test/facets_spec.lua`) after editing this package.
