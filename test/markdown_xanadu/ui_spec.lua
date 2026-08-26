local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local parse = require('markdown_xanadu.parse')
local registry = require('markdown_xanadu.registry')
local resolve = require('markdown_xanadu.resolve')
local gutter = require('markdown_xanadu.gutter')

harness.run_spec('ui', function()
  local buf = harness.load_fixture('views/viewport-scroll.md')
  local links = parse.links_in_buffer(buf)
  harness.assert_true('ui embed count', #links >= 2)

  registry.scan(buf)
  local entry = registry.get(buf)[1]
  harness.assert_true('ui registry entry', entry ~= nil)
  if entry then
    entry.resolved = resolve.resolve(buf, entry.link)
    harness.assert_true('ui resolved', entry.resolved ~= nil and entry.resolved.exists)
  end

  local chars = gutter.connector_chars(3, 10)
  harness.assert_true('ui gutter chars', #chars >= 2)

  registry.clear(buf)
  vim.api.nvim_buf_delete(buf, { force = true })
end)
