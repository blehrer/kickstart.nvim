local M = {}

M.id = 'typescript.knip'
M.requires = { 'node' }

M.trouble = {
  label = 'Knip (unused deps/exports)',
  runner = 'knip',
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

function M.detect(ctx)
  local pkg = read_package_json(ctx.root)
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
