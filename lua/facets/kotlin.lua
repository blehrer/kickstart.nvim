local M = {}

M.id = 'kotlin.jvm'
M.requires = { 'gradle' }

local function gradle_manifest(ctx)
  for _, stack in ipairs(ctx.stacks) do
    if stack.kind == 'gradle' then
      return stack.path
    end
  end
  return nil
end

local function has_kotlin_plugin(path)
  if not path or vim.fn.filereadable(path) ~= 1 then
    return false
  end
  local lines = vim.fn.readfile(path)
  local text = table.concat(lines, '\n')
  return text:find('kotlin', 1, true) ~= nil
end

function M.detect(ctx)
  local manifest = gradle_manifest(ctx)
  if not manifest then
    return false
  end
  local root = ctx.root
  if vim.fn.filereadable(root .. '/settings.gradle.kts') == 1
    or vim.fn.filereadable(root .. '/settings.gradle') == 1 then
    return has_kotlin_plugin(manifest) or vim.fn.isdirectory(root .. '/src/main/kotlin') == 1
  end
  if vim.fn.isdirectory(root .. '/src/main/kotlin') == 1 then
    return true
  end
  return has_kotlin_plugin(manifest)
end

function M.lsp(_ctx)
  return { enable = { 'kotlin_lsp', 'gradle_ls' } }
end

---@return string[]|nil formatters for conform when ktlint is available
function M.conform_formatters(_ctx)
  if vim.fn.executable('ktlint') == 1 then
    return { 'ktlint' }
  end
  local ok, registry = pcall(require, 'mason-registry')
  if ok and registry.is_installed('ktlint') then
    return { 'ktlint' }
  end
  return nil
end

return M
