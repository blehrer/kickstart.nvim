local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local complete = require('markdown_xanadu.complete')

harness.run_spec('complete', function()
  local buf = harness.load_fixture('links/gitlab-brackets.md')
  local target_buf = harness.load_fixture('edge-cases/gitlab-slugs.md')
  local target = vim.api.nvim_buf_get_name(target_buf)

  local line = '[install](../edge-cases/gitlab-slugs.md#inst'
  local ctx = complete.link_context(buf, line, #line)
  harness.assert_true('link_context found', ctx ~= nil, 'missing context')
  if ctx then
    harness.assert_suffix('target file', ctx.file, 'edge-cases/gitlab-slugs.md')
    harness.assert_eq('fragment prefix', ctx.prefix, 'inst')
    harness.assert_eq('fragment start', ctx.start, #line - #'inst' + 1)
  end

  local items = complete.anchor_items(target, 'inst')
  harness.assert_eq('completion count', #items, 1)
  if items[1] then
    harness.assert_eq('completion slug', items[1].word, 'install-macos')
    harness.assert_eq('completion menu', items[1].menu, 'Install (macOS)')
  end

  local dup = complete.anchor_items(harness.corpus_root() .. '/edge-cases/duplicate-headings.md', '')
  local slugs = {}
  for _, item in ipairs(dup) do
    slugs[#slugs + 1] = item.word
  end
  harness.assert_eq('duplicate slugs', slugs, { 'duplicate-headings', 'summary', 'summary-1' })

  vim.api.nvim_buf_delete(buf, { force = true })
  vim.api.nvim_buf_delete(target_buf, { force = true })
end)
