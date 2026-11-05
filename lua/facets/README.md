# facets

Repo-level project detection and stack tooling anchored at `git rev-parse --show-toplevel` (`plugin/facets.lua`).

## What goes here

* `anchor.lua` resolves the git root, reads JSON files (`anchor.read_json`), and collects stack manifests (`package.json`, `build.gradle.kts`, `pyproject.toml`, `go.mod`, `Cargo.toml`).
* `registry.lua` loads facet modules from `FACET_MODULES` and caches active facets by repo remote and manifest mtime.
* `eslint.lua`, `tsc.lua`, and `knip.lua` each define a facet (`id`, `requires`, `detect(ctx)`, `trouble`, optional `lsp`) alongside its async CLI runner and output parser.
* `kotlin.lua` detects Gradle/Kotlin repos, enables `kotlin_lsp` + `gradle_ls`, and wires `ktlint` for `conform.nvim`.
* `playwright/` (`init.lua`, `cli.lua`) owns Playwright detection, `neotest-playwright` adapter wiring, `.env.<configuration>` loading (`<leader>te`), `playwright test --help` flag completion/picker (`<leader>tP`), and `pwa-node` DAP (`<leader>td`).
* `trouble.lua` and `trouble_jump.lua` build and register the `facets_*` Trouble sources and modes (`<leader>xe`, `<leader>xE`, `<leader>xT`) from a single source factory.

## Conventions

* Facets own repo/stack tooling (Trouble checks, Neotest adapters, DAP, LSP enable, Conform formatters). Monorepo project scoping and target wizards live in `lua/nx/`.
* Read JSON files through `require('facets.anchor').read_json(path)`.
* Write large CLI output to a temp file (`vim.fn.tempname()`) before decoding; `vim.system` stdout can truncate large reports.
* `:FacetsInfo` prints the resolved root, stacks, and active facet IDs for the current buffer (`:FacetsInfo!` uses `cwd`).
* Run `./test/run.sh` (which includes `test/facets_spec.lua`) after editing this package.
