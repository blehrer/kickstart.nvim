local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local gutter = require('markdown_xanadu.gutter')

harness.run_spec('gutter grid', function()
  local pairs = {
    { id = 'alpha', rel_l = 3, rel_r = 1 },
    { id = 'beta', rel_l = 7, rel_r = 5 },
  }
  local grid, min_rel, max_rel = gutter.build_grid(pairs, 'alpha', true)
  harness.assert_eq('grid min row', min_rel, 1)
  harness.assert_eq('grid max row', max_rel, 7)
  harness.assert_eq('active corner', grid[1].char, '┐')
  harness.assert_eq('active hl top', grid[1].hl, 'MarkdownXanaduLinkActive')
  harness.assert_eq('inactive hl', grid[5].hl, 'MarkdownXanaduLinkInactive')

  local active_only = gutter.build_grid(pairs, 'beta', false)
  harness.assert_true('beta active row', active_only[5] ~= nil)
  harness.assert_true('alpha hidden when inactive off', active_only[1] == nil)
end)
