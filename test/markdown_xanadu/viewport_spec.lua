local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local registry = require('markdown_xanadu.registry')
local resolve = require('markdown_xanadu.resolve')
local viewport = require('markdown_xanadu.viewport')

harness.run_spec('viewport stack', function()
  local buf = harness.load_fixture('links/wiki-basic.md')
  registry.scan(buf)
  local entries = registry.get(buf)
  harness.assert_true('wiki-basic entries', #entries >= 2)

  local alpha, beta
  for _, e in ipairs(entries) do
    e.resolved = resolve.resolve(buf, e.link)
    if e.label:find('alpha') then
      alpha = e
    elseif e.label:find('beta') then
      beta = e
    end
  end
  harness.assert_true('alpha entry', alpha ~= nil)
  harness.assert_true('beta entry', beta ~= nil)

  vim.cmd('edit ' .. vim.api.nvim_buf_get_name(buf))
  local main = vim.api.nvim_get_current_win()

  viewport.open(main, alpha)
  viewport.open(main, beta)

  local cols = {}
  for _, e in ipairs(registry.open_entries(buf)) do
    if e.embed_win and vim.api.nvim_win_is_valid(e.embed_win) then
      cols[#cols + 1] = vim.api.nvim_win_get_position(e.embed_win)[2]
    end
  end
  harness.assert_eq('two embeds open', #cols, 2)
  harness.assert_eq('same embed column', cols[1], cols[2])

  local main_col = vim.api.nvim_win_get_position(main)[2]
  harness.assert_true('embeds right of main', cols[1] > main_col)

  viewport.close_all(main)
  registry.clear(buf)
  vim.api.nvim_buf_delete(buf, { force = true })
end)
