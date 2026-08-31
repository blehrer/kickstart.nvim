local config = require('markdown_xanadu.config')

local M = {}

---@param heading string
---@return string
local function slug(heading)
  return heading:lower():gsub('[^%w%s%-]', ''):gsub('%s+', '-'):gsub('%-+', '-'):gsub('^%-', ''):gsub('%-$', '')
end

---@param path string
---@return string
local function normalize_path(path)
  path = path:gsub('%.md$', '')
  return path
end

---@param base string
---@param ref string
---@return string
function M.resolve_file(base, ref)
  if ref:match('^%.%.?/') or ref:match('^%./') then
    local full = vim.fn.fnamemodify(base .. '/' .. ref, ':p')
    if vim.uv.fs_stat(full) then
      return full
    end
    local with_md = full:gsub('%.md$', '') .. '.md'
    if vim.uv.fs_stat(with_md) then
      return with_md
    end
    return with_md
  end

  ref = ref:gsub('%.md$', '')
  if ref:sub(1, 1) == '/' then
    local full = ref .. '.md'
    return vim.fn.fnamemodify(full, ':p')
  end

  local candidates = {}
  for _, root in ipairs(config.vault_roots(base)) do
    candidates[#candidates + 1] = root .. '/' .. ref .. '.md'
    candidates[#candidates + 1] = root .. '/' .. ref
  end

  for _, cand in ipairs(candidates) do
    cand = vim.fn.fnamemodify(cand, ':p')
    if vim.uv.fs_stat(cand) then
      return cand
    end
  end

  return vim.fn.fnamemodify(base .. '/' .. ref .. '.md', ':p')
end

---@param file string
---@param heading? string
---@param block_id? string
---@return integer?, integer?, string?
function M.resolve_anchor(file, heading, block_id)
  if not vim.uv.fs_stat(file) then
    return
  end
  local lines = vim.fn.readfile(file)
  if block_id then
    for i, line in ipairs(lines) do
      if line:match('%^' .. vim.pesc(block_id) .. '%s*$') or line:match('%^' .. vim.pesc(block_id) .. '%s') then
        return i, 0
      end
    end
  end
  if heading then
    local want = heading:lower()
    local want_slug = slug(heading)
    for i, line in ipairs(lines) do
      local _, text = line:match('^(#+%s+)(.+)$')
      if text then
        local tl = text:lower()
        local text_slug = slug(text)
        if tl == want or text_slug == want_slug or text_slug == slug(want) then
          return i, 0
        end
      end
    end
  end
  return 1, 0
end

---@param bufnr integer
---@param link markdown_xanadu.Link
---@return { file: string, line: integer, col: integer, exists: boolean }?
function M.resolve(bufnr, link)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local base = name ~= '' and vim.fn.fnamemodify(name, ':h') or config.fixture_root()
  local path = normalize_path(link.path)
  local file = M.resolve_file(base, path)
  local exists = vim.uv.fs_stat(file) ~= nil
  if not exists then
    return nil
  end
  local line, col = M.resolve_anchor(file, link.heading, link.block_id)
  line = line or 1
  col = col or 0
  return { file = file, line = line, col = col, exists = true }
end

---@param bufnr integer
---@param link { path: string, heading?: string, block_id?: string }
---@return { file: string, line: integer, col: integer }?
function M.resolve_spec(bufnr, link)
  local fake = {
    kind = 'link',
    raw = '',
    path = link.path,
    heading = link.heading,
    block_id = link.block_id,
    range = { 0, 0, 0, 0 },
  }
  local r = M.resolve(bufnr, fake)
  if not r then
    return nil
  end
  return { file = r.file, line = r.line, col = r.col }
end

---@param resolved { file: string }
---@return string
function M.display_path(resolved)
  local root = config.fixture_root()
  local rel = vim.fn.fnamemodify(resolved.file, ':.')
  if rel:find(root, 1, true) == 1 then
    rel = rel:sub(#root + 2)
  end
  return rel
end

return M
