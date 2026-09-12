local function h()
  return package.loaded['xanadu_test_harness'] or dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
end

local harness = h()
local resolve = require('markdown_xanadu.resolve')

harness.run_spec('gitlab_slug', function()
  local cases = {
    { 'Install (macOS)', 'install-macos' },
    { 'This heading has 3.5 in it (and parentheses)', 'this-heading-has-35-in-it-and-parentheses' },
    {
      'This heading has  multiple spaces and --- hyphens',
      'this-heading-has--multiple-spaces-and-----hyphens',
    },
    { 'This heading has a :thumbsup: in it', 'this-heading-has-a-thumbsup-in-it' },
  }
  for _, case in ipairs(cases) do
    harness.assert_eq('gitlab_slug ' .. case[1], resolve.gitlab_slug(case[1]), case[2])
  end

  local fixture = harness.corpus_root() .. '/edge-cases/duplicate-headings.md'
  local anchors = resolve.heading_anchors(fixture)
  harness.assert_eq('duplicate anchor line 3', anchors[3], 'summary')
  harness.assert_eq('duplicate anchor line 7', anchors[7], 'summary-1')
end)
