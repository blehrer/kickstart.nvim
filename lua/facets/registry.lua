local anchor = require('facets.anchor')

local M = {}

local FACET_MODULES = {
  'facets.typescript.eslint',
  'facets.playwright.e2e',
  'facets.kotlin.jvm',
}

local facet_defs = {}
local active_cache = {}
M.last_ctx = nil

local function load_facets()
  if #facet_defs > 0 then
    return facet_defs
  end
  for _, mod in ipairs(FACET_MODULES) do
    local ok, def = pcall(require, mod)
    if ok and type(def) == 'table' and def.id and def.detect then
      facet_defs[#facet_defs + 1] = def
    else
      vim.notify('facets: failed to load ' .. mod, vim.log.levels.WARN)
    end
  end
  return facet_defs
end

local function requires_met(def, ctx)
  if not def.requires or #def.requires == 0 then
    return true
  end
  for _, kind in ipairs(def.requires) do
    if not ctx.stack_kinds[kind] then
      return false
    end
  end
  return true
end

function M.invalidate()
  active_cache = {}
end

function M.remember_ctx(ctx)
  if ctx and ctx.root then
    M.last_ctx = ctx
  end
end

--- Resolve anchor: current buffer, cwd, then last file-backed repo (e.g. tree/picker focused).
---@param bufnr number|nil
---@return table|nil ctx
function M.resolve_smart(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ctx = M.resolve(bufnr)
  if ctx then
    return ctx
  end
  ctx = M.resolve(vim.loop.cwd())
  if ctx then
    return ctx
  end
  return M.last_ctx
end

---@param ctx table|nil from anchor.resolve
---@return table[] active facet defs with optional meta
function M.active(ctx)
  if not ctx then
    return {}
  end
  local cached = active_cache[ctx.cache_key]
  if cached then
    return cached
  end

  local out = {}
  for _, def in ipairs(load_facets()) do
    if requires_met(def, ctx) then
      local ok, detected, meta = pcall(def.detect, ctx)
      if ok and detected then
        out[#out + 1] = { def = def, meta = meta }
      end
    end
  end
  active_cache[ctx.cache_key] = out
  return out
end

---@param start string|number|nil
---@return table|nil ctx
function M.resolve(start)
  return anchor.resolve(start)
end

---@param start string|number|nil
---@return table[] active
function M.active_for(start)
  return M.active(M.resolve(start))
end

--- Active facet ids for a buffer path (convenience).
---@param bufnr number|nil
---@return string[]
function M.active_ids(bufnr)
  bufnr = bufnr or 0
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    path = nil
  end
  local ctx = M.resolve(path or bufnr)
  local ids = {}
  for _, entry in ipairs(M.active(ctx)) do
    ids[#ids + 1] = entry.def.id
  end
  return ids
end

function M.has_facet(id, start)
  for _, entry in ipairs(M.active_for(start)) do
    if entry.def.id == id then
      return true
    end
  end
  return false
end

return M
