# Project facet templates

Design for git-root project facets in kickstart.nvim. Implementation lives under `lua/facets/`.

## Anchor

- **Boundary:** `git rev-parse --show-toplevel` (non-git repos have no facet anchor; `:FacetsInfo` explains).
- **Stacks:** All manifests present at the git root are collected—no precedence between stacks (polyglot repos can activate multiple facets).

| Stack kind | Manifest at repo root |
|------------|------------------------|
| `node` | `package.json` |
| `gradle` | `build.gradle.kts`, else `build.gradle` |
| `python` | `pyproject.toml` |
| `go` | `go.mod` |
| `rust` | `Cargo.toml` |

## Facets (v1)

| ID | Requires | Detection (git root) | Integrations |
|----|----------|----------------------|--------------|
| `typescript.eslint` | `node` | ESLint config files or `eslint` / `@eslint/*` in `package.json` | ESLint LSP; `facet.trouble` → picker / `<leader>xE` → Trouble |
| `typescript.tsc` | `node` | `tsconfig.json` or `tsconfig.build.json` at git root | `facet.trouble` → picker / `<leader>xT` → Trouble |
| `typescript.knip` | `node` | `knip` in root `package.json` `devDependencies` or `dependencies` | `facet.trouble` → picker; `knip --reporter json` → Trouble |

Facets that define `trouble = { label, runner }` appear in `<leader>xe` (Snacks select). Runners and Trouble sources are built in `lua/facets/trouble.lua` (`SPECS` / `make_source`).
| `playwright.e2e` | `node` | Root Playwright config or `@playwright/test` dep (`lua/facets/playwright/`) | `neotest-playwright`, `.env.<cfg>` (`<leader>te`), CLI flags (`<leader>tP`), `pwa-node` DAP (`<leader>td`) |
| `kotlin.jvm` | `gradle` | Kotlin plugin / `src/main/kotlin` / settings.gradle (`lua/facets/kotlin.lua`) | `kotlin_lsp` + `gradle_ls` enable; conform `ktlint` when available |

## Nx

Nx remains a **scope overlay**: `<leader>xp` / `nx.trouble` filter diagnostics to an Nx project (and optional dependents), and `<leader>nx` / `<leader>nt` drive the Nx target wizard (`lua/nx/`). Facets describe stack tooling (`lua/facets/`).

Nested Playwright configs under Nx apps are still discovered by `facets.playwright` (`find_pw_config_dir`) even when the root facet is off.

## Commands

- `:FacetsInfo` — git root, stacks, active facet ids.

## Follow-up (tracked in beads)

- Shallow monorepo facet scan (e.g. `apps/*/playwright.config.ts`).
- `.editor-project-root` override.
- neotest Gradle/JUnit and Kotlin DAP templates.
- Dynamic neotest adapter registration when opening a repo without restarting Neovim.
