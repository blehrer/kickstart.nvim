local registry = require('facets.registry')

local M = {}

local enabled_for_repo = {}

local function apply_dap_spec(spec)
  local ok_dap, dap = pcall(require, 'dap')
  if not ok_dap or type(spec) ~= 'table' then
    return
  end
  for name, adapter in pairs(spec.adapters or {}) do
    dap.adapters[name] = adapter
  end
  for ft, configs in pairs(spec.configurations or {}) do
    dap.configurations[ft] = configs
  end
end

--- Register baseline DAP adapters/configurations from all facets (cwd fallback before repo attach).
function M.setup_dap_defaults()
  local fallback_ctx = registry.resolve_smart(0) or { root = vim.loop.cwd() }
  for _, def in ipairs(registry.all_defs()) do
    if def.dap then
      local ok, spec = pcall(def.dap, fallback_ctx)
      if ok and spec then
        apply_dap_spec(spec)
      end
    end
  end
end

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
    if entry.def.dap then
      local ok, spec = pcall(entry.def.dap, ctx, entry.meta)
      if ok and spec then
        apply_dap_spec(spec)
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
