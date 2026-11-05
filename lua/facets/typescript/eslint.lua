local workspace = require('nx.workspace')

local M = {}

M.id = 'typescript.eslint'
M.requires = { 'node' }

M.trouble = {
  label = 'ESLint (npx eslint .)',
  runner = 'eslint',
}

local CONFIG_NAMES = {
  'eslint.config.js',
  'eslint.config.mjs',
  'eslint.config.cjs',
  '.eslintrc',
  '.eslintrc.json',
  '.eslintrc.cjs',
  '.eslintrc.yaml',
  '.eslintrc.yml',
}

local function deps_have_eslint(pkg)
  if not pkg then
    return false
  end
  for _, key in ipairs({ 'dependencies', 'devDependencies', 'peerDependencies' }) do
    local deps = pkg[key]
    if type(deps) == 'table' then
      for name in pairs(deps) do
        if name == 'eslint' or name:match('^@eslint/') then
          return true
        end
      end
    end
  end
  return false
end

function M.detect(ctx)
  for _, name in ipairs(CONFIG_NAMES) do
    if vim.fn.filereadable(ctx.root .. '/' .. name) == 1 then
      return true
    end
  end
  if deps_have_eslint(workspace.read_json(ctx.root .. '/package.json')) then
    return true
  end
  return false
end

function M.lsp(_ctx)
  return { enable = { 'eslint' } }
end

return M
