# Markdown Xanadu Fixture Index

Hub linking every test scenario in this vault.

## Links (syntax)

- [[links/wiki-basic]] — plain wiki links and embeds
- [[links/wiki-deep]] — heading, block-id, chained embeds
- [[links/standard-md]] — standard markdown links
- [[links/mixed-syntax]] — wiki + standard on same page

## Targets (resolution)

- [[targets/alpha]] — heading ladder + block IDs
- [[targets/beta]] — second-hop target
- [[targets/nested/deep/note]] — nested directory paths

## Graphs (backlinks)

- [[graphs/hub]] — outbound hub
- [[graphs/spoke-a]] / [[graphs/spoke-b]] — spokes
- [[graphs/chain-start]] → [[graphs/chain-mid]] → [[graphs/chain-end]]

## Views (UI walkthroughs)

- [[views/sidebar-tour]] — named-links column
- [[views/viewport-scroll]] — gutter scroll tracking
- [[views/multi-embed]] — LRU embed limit
- [[views/backlinks-tour]] — `gr` references

## Edge cases

- [[edge-cases/duplicate-headings]]
- [[edge-cases/missing-target]]
- [[edge-cases/escaped-and-literal]]

Run automated tests: `./scripts/test-markdown-xanadu.sh`

Demo command in Neovim: `:MarkdownXanaduDemo`
