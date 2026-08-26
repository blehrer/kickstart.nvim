local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local cases = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
local resolve = require('markdown_xanadu.resolve')

harness.run_spec('resolve', function()
  for _, case in ipairs(cases.resolve) do
    local buf = harness.load_fixture(case.from)
    local got = resolve.resolve_spec(buf, case.link)
    if case.expect == nil then
      harness.assert_eq('resolve nil ' .. case.from, got, nil)
    else
      harness.assert_true('resolve got', got ~= nil, case.from)
      if got then
        harness.assert_suffix('resolve file', got.file, case.expect.file_suffix)
        harness.assert_eq('resolve line', got.line, case.expect.line)
        harness.assert_eq('resolve col', got.col, case.expect.col)
      end
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end)
