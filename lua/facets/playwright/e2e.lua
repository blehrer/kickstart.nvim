local M = {}

M.id = 'playwright.e2e'
M.requires = { 'node' }

local PW_CONFIGS = {
  'playwright.config.ts',
  'playwright.config.js',
  'playwright.config.mjs',
}

local function read_package_json(root)
  local path = root .. '/package.json'
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local ok, data = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(path), '\n'))
  if not ok or type(data) ~= 'table' then
    return nil
  end
  return data
end

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
  return has_playwright_dep(read_package_json(ctx.root))
end

return M
