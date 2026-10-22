local registry = require('facets.registry')

local M = {}

local enabled_for_repo = {}

---@param bufnr number
function M.apply_for_buffer(bufnr)
  if vim.bo[bufnr].buftype ~= '' or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    return
  end
  local ctx = registry.resolve(path)
  if not ctx then
    return
  end
  if enabled_for_repo[ctx.cache_key] then
    return
  end

  local servers = {}
  for _, entry in ipairs(registry.active(ctx)) do
    if entry.def.lsp then
      local ok, spec = pcall(entry.def.lsp, ctx, entry.meta)
      if ok and spec and spec.enable then
        for _, name in ipairs(spec.enable) do
          servers[name] = true
        end
      end
    end
  end

  for name in pairs(servers) do
    pcall(vim.lsp.enable, name)
  end
  enabled_for_repo[ctx.cache_key] = true
end

function M.invalidate()
  enabled_for_repo = {}
end

return M
