# Markdown Xanadu Test Fixtures

Fixture vault for manual walkthroughs and automated headless tests.

## Run tests

```bash
./scripts/test-markdown-xanadu.sh
```

## Scenario matrix

| Folder | Deep linking | Cross-source refs | Buffer view |
|--------|--------------|-------------------|-------------|
| `links/` | heading + block anchors | — | main buffer `gd` / highlight |
| `targets/` | anchor landing zones | inbound from links, graphs | embed viewport scroll-to |
| `graphs/` | chain-start → chain-end | hub/spoke backlink graph | `gr` picker results |
| `views/` | embeds at varied offsets | multi-file embed set | sidebar, viewport, gutter |
| `edge-cases/` | duplicate heading pick | — | error paths |

## Manual demo

```bash
cd test/fixtures/markdown_xanadu && nvim 00-index.md
```

Then `:MarkdownXanaduDemo` or `<A-2>` to open panels.

Expectations live in `test/markdown_xanadu/cases.lua`.
