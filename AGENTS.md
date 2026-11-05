# Agent Guide & Repository Sitemap

Neovim 0.12+ configuration (`NVIM_APPNAME=kickstart.nvim`, datadir `~/.local/share/kickstart.nvim`) using native `vim.pack`, experimental `ui2` + `tiny-cmdline`, and `snacks.nvim` as the sole picker.

Before editing a subsystem, **read the linked `README.md` or spec** in the sitemap below rather than scanning the whole tree.

## Repository Sitemap

| Area | Entrypoints | Detailed Docs (Read First) |
|------|-------------|----------------------------|
| **Core editor & startup** | `init.lua`, `lua/config/` (`options`, `keymaps`, `autocmds`, `ui2`, `exrc`, `statusline`) | `lua/config/README.md` |
| **Filetype detection** | `filetype.lua` (root `vim.filetype.add` rules; no `after/ftdetect/`) | `filetype.lua` |
| **Per-filetype buffer setup** | `after/ftplugin/<ft>.lua` (`markdown`, `oil`, `http`, `sql`, `mysql`, `plsql`) | `plugin/README.md` |
| **Plugins & global keymaps** | `plugin/*.lua` (ordered `05-`..`30-` where load order matters, alphabetical otherwise) | `plugin/README.md` |
| **LSP servers & panels** | `lsp/<server>.lua` (per-server overrides), `lua/config/lsp.lua`, `lua/config/lsp_panels.lua`, `lua/config/lsp_symbol_sources.lua` | `lua/config/README.md` |
| **Formatting & CI deference** | `plugin/format.lua`, `lua/format/` (`policy`, `deference`, `hunks`, `markdown`, `save_toggle`) | `lua/format/README.md` |
| **Project facets (git-root)** | `plugin/facets.lua`, `lua/facets/` (`:FacetsInfo`, `<leader>xe` / `<leader>xE` / `<leader>xT`) | `lua/facets/README.md`, `docs/specs/2026-10-22-project-facets-design.md` |
| **Nx & Playwright** | `plugin/nx.lua`, `plugin/neotest.lua`, `plugin/dap.lua`, `lua/nx/` (`<leader>nx`, `<leader>nt`, `<leader>xp`) | `lua/nx/README.md` |
| **Markdown Xanadu** | `plugin/markdown-xanadu.lua`, `after/ftplugin/markdown.lua`, `lua/markdown_xanadu/` (`<A-2>`) | `lua/markdown_xanadu/README.md`, `test/fixtures/markdown_xanadu/README.md` |
| **Git mergetool overlay** | `plugin/merge-tool-help.lua`, `lua/merge-tool-help/` (`<F1>`, `:MergeToolHelp`) | `lua/merge-tool-help/README.md` |
| **Cursor (`vscode-neovim`)** | `cursor/nvim-init.lua`, `cursor/settings.json`, `cursor/keybindings.json`, `cursor/sync.sh` | `cursor/README.md` |
| **Tests & operational scripts** | `test/run.sh`, `test/*_spec.lua`, `scripts/reinstall-plugins.sh`, `scripts/kls-classpath-gradlew.sh` | `README.md` |

## Conventions & Preferences

- **Plugins:** Declare plugins with native `vim.pack.add` in `plugin/*.lua` (guarded with `if vim.g.vscode then return end`). When translating `lazy.nvim` configs, skip conflicting keymaps and report what was skipped.
- **Runtimepath layout:**
  - Put `vim.filetype.add` rules in root `filetype.lua` (never `after/ftdetect/`).
  - Put buffer-local filetype options/keymaps in `after/ftplugin/<ft>.lua` instead of `FileType` autocmds in `plugin/*.lua`.
  - Put per-server LSP overrides in `lsp/<server>.lua`; keep global `vim.lsp.config('*', ...)`, `ensure_installed`, `LspAttach`, and LSP keymaps in `lua/config/lsp.lua`.
- **Cursor parity:** Use `vscode-neovim` with a slim profile (`cursor/nvim-init.lua`), never VSCodeVim. `<leader>ff` (hunks/changes), `<leader>fF` (whole file), and `<leader>uf` (toggle format-on-save + EditorConfig) match between terminal Neovim and Cursor.
- **Key workflows & defaults:**
  - `<C-/>` toggles the Snacks terminal; `sidekick.nvim` uses the `zellij` mux backend (`plugin/sidekick.lua`).
  - `<leader>gx` copies a GitLab/GitHub file URL to `+`/`*` via Snacks gitbrowse (`plugin/30-snacks.lua`, `lua/config/gitbrowse.lua`) with a 2s notification and no browser; GitLab MR reviews use `codereview.nvim` (`<leader>gm`) with token from 1Password.
  - Playwright e2e tests default to INT/QAT SSO (not localhost); primary debug target is `legal-web-playwright-e2e` with `shared-auth-setup`.
  - Kotlin uses JetBrains `kotlin_lsp` (`lsp/kotlin_lsp.lua`); `kotlin_language_server` (fwcd) is excluded from Mason auto-enable because embedded Kotlin 2.1 fails on Gradle 9 / stdlib 2.3 metadata. `:KlsRestart` restarts Kotlin LSP and clears `kls_database.db`.
- **Verification:** Run `./test/run.sh` after changing plugins, runtimepath files, or `lua/` modules.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd export --no-memories -o .beads/issues.jsonl
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - `./test/run.sh`
3. **Update issue status** - Close finished work, update in-progress items, export `.beads/issues.jsonl`
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
