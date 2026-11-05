# markdown_xanadu

Side-by-side transclusion viewports, link sidebar, gutter connectors, backlinks, and GitLab heading-anchor completion for Markdown buffers (`plugin/markdown-xanadu.lua`).

## What goes here

* `parse.lua` and `resolve.lua` parse `[[wiki]]` and `[md](path#heading)` links, compute GitLab GLFM heading slugs, and resolve target files and line numbers.
* `registry.lua` and `focus.lua` track links per buffer and which transclusion embed windows are open.
* `sidebar.lua`, `viewport.lua`, `gutter.lua`, and `highlight.lua` manage the link list split, stacked right-hand embed splits, 1-column connector float, and link highlights.
* `complete.lua` provides `#heading` omnifunc completion (`v:lua.markdown_xanadu_omni`), and `backlinks.lua` finds incoming links with `rg`.

## Conventions

* Buffer-local markdown mappings (`gd`, `gD`, `gr`, `<leader>yh`) attach in `init.setup_buffer` and fall back to LSP when the cursor is not on a markdown link.
* Keep pure parsing, slugging, and grid math separate from window mutations so `test/markdown_xanadu/*_spec.lua` can test them headlessly.
* Run `./test/run.sh` after editing this module.
