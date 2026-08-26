local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local cases = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
local registry = require('markdown_xanadu.registry')

harness.run_spec('registry', function()
  for _, case in ipairs(cases.registry) do
    local buf = harness.load_fixture(case.file)
    local entries = registry.scan(buf)
    harness.assert_eq('registry count ' .. case.file, #entries, case.expect_entries)
    if case.open then
      local entry = registry.entry_at_line(buf, case.open.line)
      harness.assert_true('registry entry at line', entry ~= nil)
      if entry and case.expect_open then
        entry.resolved = require('markdown_xanadu.resolve').resolve(buf, entry.link)
        harness.assert_true('registry resolved', entry.resolved ~= nil)
        if entry.resolved then
          harness.assert_suffix('registry open path', entry.resolved.file, case.expect_open[1])
        end
      end
    end
    registry.clear(buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end)
