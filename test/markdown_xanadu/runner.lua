local M = {}

local function harness()
  local key = 'xanadu_test_harness'
  if not package.loaded[key] then
    package.loaded[key] = dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/harness.lua')
  end
  return package.loaded[key]
end

local function cases()
  return dofile(vim.fn.getcwd() .. '/test/markdown_xanadu/cases.lua')
end

function M.run()
  local cwd = vim.fn.getcwd()
  vim.opt.rtp:prepend(cwd)

  local h = harness()
  h.reset()
  package.loaded['xanadu_test_harness'] = h

  local specs = {
    'parse_spec.lua',
    'resolve_spec.lua',
    'backlinks_spec.lua',
    'registry_spec.lua',
    'gutter_spec.lua',
    'ui_spec.lua',
  }

  for _, spec in ipairs(specs) do
    local fn = loadfile(cwd .. '/test/markdown_xanadu/' .. spec)
    if not fn then
      error('missing spec: ' .. spec)
    end
    fn()
  end

  if #h.errors > 0 then
    for _, err in ipairs(h.errors) do
      vim.print('FAIL: ' .. err)
    end
  end

  vim.print(('PASS %d / FAIL %d'):format(h.pass, h.fail))
  if h.fail > 0 then
    os.exit(1)
  end
end

return M
