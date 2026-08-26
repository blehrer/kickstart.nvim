local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local cases = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
local gutter = require('markdown_xanadu.gutter')

harness.run_spec('gutter', function()
  for i, case in ipairs(cases.gutter) do
    local chars = gutter.connector_chars(case.left_row, case.right_row)
    for _, c in ipairs(case.expect_chars) do
      local found = false
      for _, ch in ipairs(chars) do
        if ch == c then
          found = true
          break
        end
      end
      harness.assert_true('gutter char ' .. c .. ' case ' .. i, found)
    end
    local merged = gutter.chars_for_pairs({ { left_row = case.left_row, right_row = case.right_row } })
    harness.assert_true('gutter merged case ' .. i, #merged >= 1)
  end
end)
