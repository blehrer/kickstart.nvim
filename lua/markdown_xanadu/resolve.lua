local config = require('markdown_xanadu.config')

local M = {}

---@param path string
---@return boolean
local function readable_file(path)
  return path ~= '' and vim.fn.isdirectory(path) ~= 1 and vim.fn.filereadable(path) == 1
end

---@param path string
---@return string[]?
local function read_lines(path)
  if not readable_file(path) then
    return nil
  end
  return vim.fn.readfile(path)
end

--- GitLab GLFM base slug (duplicate suffix applied separately).
---@param heading string
---@return string
function M.gitlab_slug(heading)
  heading = heading:lower()
  local out = {}
  local len = vim.fn.strchars(heading)
  for i = 0, len - 1 do
    local c = vim.fn.strcharpart(heading, i, 1)
    if c == ' ' then
      out[#out + 1] = '-'
    elseif c == '-' or c == '_' then
      out[#out + 1] = c
    elseif c:match('^%d$') or c:match('^%a$') then
      out[#out + 1] = c
    elseif vim.fn.strchars(c) == 1 then
      -- ponytail: non-ASCII letters kept; punctuation dropped (GLFM unicode headings)
      local n = vim.fn.char2nr(c)
      if n > 127 and not c:match('^%p$') then
        out[#out + 1] = c
      end
    end
  end
  return table.concat(out)
end

---@param lines string[]
---@return table<integer, string>
function M.heading_anchors_from_lines(lines)
  local counts = {}
  local anchors = {}
  for i, line in ipairs(lines) do
    local text = line:match('^#+%s+(.+)$')
    if text then
      local base = M.gitlab_slug(text)
      local n = counts[base] or 0
      anchors[i] = n > 0 and (base .. '-' .. n) or base
      counts[base] = n + 1
    end
  end
  return anchors
end

---@param file string
---@return table<integer, string>
function M.heading_anchors(file)
  local lines = read_lines(file)
  if not lines then
    return {}
  end
  return M.heading_anchors_from_lines(lines)
end

---@param file string
---@return string
function M.relative_markdown_path(file)
  local dir = vim.fn.fnamemodify(file, ':h')
  local out = vim.fn.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error == 0 then
    local root = vim.fn.fnamemodify(vim.trim(out), ':p'):gsub('/$', '')
    if file:find(root, 1, true) == 1 then
      return file:sub(#root + 2)
    end
  end
  return vim.fn.fnamemodify(file, ':.')
end

---@param lines string[]
---@param line_nr integer
---@return integer?, string?
local function heading_at_or_before(lines, line_nr)
  for i = line_nr, 1, -1 do
    local text = lines[i] and lines[i]:match('^#+%s+(.+)$')
    if text then
      return i, text
    end
  end
end

---@param file string
---@param line_nr integer
---@return { file: string, line: integer, anchor: string, path: string, link: string }?
function M.link_target_for_line(file, line_nr)
  local lines = read_lines(file)
  if not lines then
    return
  end
  local hline = select(1, heading_at_or_before(lines, line_nr))
  if not hline then
    return
  end
  local anchors = M.heading_anchors_from_lines(lines)
  local anchor = anchors[hline]
  if not anchor then
    return
  end
  local path = M.relative_markdown_path(file)
  return {
    file = file,
    line = hline,
    anchor = anchor,
    path = path,
    link = path .. '#' .. anchor,
  }
end

---@param bufnr? integer
---@param line_nr? integer
function M.yank_anchor(bufnr, line_nr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  line_nr = line_nr or vim.api.nvim_win_get_cursor(0)[1]
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    vim.notify('markdown_xanadu: buffer has no file path', vim.log.levels.WARN)
    return
  end
  local target = M.link_target_for_line(file, line_nr)
  if not target then
    vim.notify('markdown_xanadu: no heading above cursor', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', target.link)
  vim.notify('Yanked ' .. target.link, vim.log.levels.INFO)
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
    if readable_file(full) then
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
    if readable_file(cand) then
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
  local lines = read_lines(file)
  if not lines then
    return
  end
  if block_id then
    for i, line in ipairs(lines) do
      if line:match('%^' .. vim.pesc(block_id) .. '%s*$') or line:match('%^' .. vim.pesc(block_id) .. '%s') then
        return i, 0
      end
    end
  end
  if heading then
    local want = heading:lower()
    local want_slug = M.gitlab_slug(heading)
    local anchors = M.heading_anchors_from_lines(lines)
    for i, line in ipairs(lines) do
      local text = line:match('^#+%s+(.+)$')
      if text then
        local anchor = anchors[i]
        if anchor == want or anchor == want_slug then
          return i, 0
        end
      end
    end
    for i, line in ipairs(lines) do
      local text = line:match('^#+%s+(.+)$')
      if text and text:lower() == want then
        return i, 0
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
  if not readable_file(file) then
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
