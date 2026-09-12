local config = require('markdown_xanadu.config')
local resolve = require('markdown_xanadu.resolve')

local M = {}

---@class markdown_xanadu.CompleteCtx
---@field file string
---@field start integer 1-indexed column where fragment completion begins
---@field prefix string

local ctx_cache = {}

local SAME_PAGE = {
  '%]%(#([^%)-]-)$',
  '%[%[#([^%]]-)$',
}

---@type [string, integer, integer][]
local WITH_PATH = {
  { '%[%[([^#%]]*)#([^%]]-)$', 1, 2 },
  { '%]%(([^#)]*)#([^%)-]-)$', 1, 2 },
  { '%]%(<([^#>]*)#([^>]-)$', 1, 2 },
  { '^%[[^%]]*%]:%s*([^#%s]+)#(%S-)$', 1, 2 },
}

---@param bufnr integer
---@param path string
---@return string?
local function target_file(bufnr, path)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local base = name ~= '' and vim.fn.fnamemodify(name, ':h') or config.fixture_root()
  if path == '' then
    return name ~= '' and name or nil
  end
  path = path:gsub('%.md$', '')
  return resolve.resolve_file(base, path)
end

---@param bufnr integer
---@param line string
---@param col integer 1-indexed cursor column
---@return markdown_xanadu.CompleteCtx?
function M.link_context(bufnr, line, col)
  local before = line:sub(1, col)

  for _, re in ipairs(SAME_PAGE) do
    local s, e, frag = before:find(re)
    if s then
      local file = target_file(bufnr, '')
      if file and vim.uv.fs_stat(file) then
        return { file = file, start = e - #frag + 1, prefix = frag }
      end
    end
  end

  for _, spec in ipairs(WITH_PATH) do
    local s, e, path, frag = before:find(spec[1])
    if s then
      local file = target_file(bufnr, path)
      if file and vim.uv.fs_stat(file) then
        return { file = file, start = e - #frag + 1, prefix = frag }
      end
    end
  end
end

---@param file string
---@param prefix string
---@return { word: string, menu: string, line: integer }[]
function M.anchor_items(file, prefix)
  if not vim.uv.fs_stat(file) or vim.fn.isdirectory(file) == 1 then
    return {}
  end
  local lines = vim.fn.readfile(file)
  local anchors = resolve.heading_anchors_from_lines(lines)
  local want = prefix:lower()
  local items = {}
  for line_nr, anchor in pairs(anchors) do
    if want == '' or anchor:find(want, 1, true) == 1 then
      local text = lines[line_nr]:match('^#+%s+(.+)$') or anchor
      items[#items + 1] = { word = anchor, menu = text, line = line_nr }
    end
  end
  table.sort(items, function(a, b)
    return a.line < b.line
  end)
  return items
end

---@param findstart integer
---@param base string
---@return integer|table
function M.omni(findstart, base)
  local bufnr = vim.api.nvim_get_current_buf()
  if findstart == 1 then
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local ctx = M.link_context(bufnr, line, col)
    if not ctx then
      ctx_cache[bufnr] = nil
      return -1
    end
    ctx_cache[bufnr] = ctx
    return ctx.start
  end

  local ctx = ctx_cache[bufnr]
  if not ctx then
    return {}
  end

  local items = M.anchor_items(ctx.file, base)
  local out = {}
  for _, item in ipairs(items) do
    out[#out + 1] = { word = item.word, menu = item.menu }
  end
  return out
end

function _G.markdown_xanadu_omni(findstart, base)
  return M.omni(findstart, base)
end

return M
