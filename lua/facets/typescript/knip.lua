local workspace = require('nx.workspace')

local M = {}

M.id = 'typescript.knip'
M.requires = { 'node' }

M.trouble = {
  label = 'Knip (unused deps/exports)',
  runner = 'knip',
}

function M.detect(ctx)
  local pkg = workspace.read_json(ctx.root .. '/package.json')
  if not pkg then
    return false
  end
  for _, key in ipairs({ 'devDependencies', 'dependencies' }) do
    local deps = pkg[key]
    if type(deps) == 'table' and deps.knip then
      return true
    end
  end
  return false
end

return M
