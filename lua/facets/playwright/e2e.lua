local workspace = require('nx.workspace')

local M = {}

M.id = 'playwright.e2e'
M.requires = { 'node' }

local PW_CONFIGS = {
  'playwright.config.ts',
  'playwright.config.js',
  'playwright.config.mjs',
}

local function has_playwright_dep(pkg)
  if not pkg then
    return false
  end
  for _, key in ipairs({ 'dependencies', 'devDependencies' }) do
    local deps = pkg[key]
    if type(deps) == 'table' and deps['@playwright/test'] then
      return true
    end
  end
  return false
end

function M.detect(ctx)
  for _, name in ipairs(PW_CONFIGS) do
    if vim.fn.filereadable(ctx.root .. '/' .. name) == 1 then
      return true
    end
  end
  return has_playwright_dep(workspace.read_json(ctx.root .. '/package.json'))
end

return M
