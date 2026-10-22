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
| `typescript.eslint` | `node` | ESLint config files or `eslint` / `@eslint/*` in `package.json` | ESLint LSP (inline diagnostics; flat config in `lsp.lua`), `<leader>xe` = full-repo CLI lint → Trouble |
| `playwright.e2e` | `node` | Root Playwright config or `@playwright/test` dep | neotest-playwright when facet or nested config (`find_pw_config_dir`) |
| `kotlin.jvm` | `gradle` | Kotlin plugin / `src/main/kotlin` / settings.gradle | `kotlin_lsp` + `gradle_ls` enable; conform `ktlint` when available |

## Nx

Nx remains a **scope overlay**: `<leader>xp` / `nx.trouble` filter diagnostics to an Nx project (and optional dependents). Facets describe repo-level tooling at the git root.

Nested Playwright/ESLint configs under Nx apps are still discovered by `nx.playwright` (`find_pw_config_dir`) even when the root facet is off.

## Commands

- `:FacetsInfo` — git root, stacks, active facet ids.

## Follow-up (tracked in beads)

- Shallow monorepo facet scan (e.g. `apps/*/playwright.config.ts`).
- `.editor-project-root` override.
- neotest Gradle/JUnit and Kotlin DAP templates.
- Dynamic neotest adapter registration when opening a repo without restarting Neovim.
