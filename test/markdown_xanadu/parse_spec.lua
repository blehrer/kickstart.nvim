local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local cases = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
local parse = require('markdown_xanadu.parse')

harness.run_spec('parse', function()
  for i, case in ipairs(cases.parse) do
    local buf = harness.load_fixture(case.file)
    if case.scan then
      local links = parse.links_in_buffer(buf)
      harness.assert_eq('parse scan count ' .. case.file, #links, case.expect_count)
      if case.expect_paths then
        local paths = {}
        for _, l in ipairs(links) do
          paths[l.path] = true
        end
        for _, p in ipairs(case.expect_paths) do
          harness.assert_true('parse path ' .. p, paths[p] == true, 'missing ' .. p)
        end
      end
    else
      local link = parse.link_at_cursor(buf, case.line, case.col)
      harness.assert_true('parse cursor ' .. case.file, link ~= nil, 'no link at cursor')
      if link and case.expect then
        harness.assert_eq('parse kind', link.kind, case.expect.kind)
        harness.assert_eq('parse path', link.path, case.expect.path)
      end
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end)
