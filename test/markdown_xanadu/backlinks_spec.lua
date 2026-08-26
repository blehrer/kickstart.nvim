local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local cases = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
local backlinks = require('markdown_xanadu.backlinks')

harness.run_spec('backlinks', function()
  for _, case in ipairs(cases.backlinks) do
    local root = harness.corpus_root()
    local file = root .. '/' .. case.file
    local got = backlinks.find_sync(file, root)
    local got_set = {}
    for _, f in ipairs(got) do
      local rel = f:gsub('^.*/markdown_xanadu/', '')
      got_set[rel] = true
    end
    for _, expect in ipairs(case.expect_files) do
      harness.assert_true('backlink ' .. expect, got_set[expect] == true, 'missing backlink')
    end
  end
end)
