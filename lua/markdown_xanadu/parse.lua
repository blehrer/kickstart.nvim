local M = {}

---@class markdown_xanadu.Link
---@field kind 'link'|'embed'
---@field raw string
---@field path string
---@field heading? string
---@field block_id? string
---@field range integer[] {sr, sc, er, ec} 0-indexed

local WIKI_INNER = '(!?)%[%[([^%]%]]+)%]%]'
local MD_LINK_RE = '%[([^%]]*)%]%(([^%)]+)%)'

---@param inner string
---@return string?, string?, string?
local function parse_wiki_inner_text(inner)
  inner = vim.trim(inner)
  if inner == '' then
    return
  end
  local path, tail = inner:match('^([^#^]+)(.*)$')
  if not path or path == '' then
    return
  end
  local heading = tail and tail:match('#([^%^]+)') or nil
  local block = tail and tail:match('%^([^%]]+)') or nil
  if heading == '' then
    heading = nil
  end
  if block == '' then
    block = nil
  end
  return path, heading, block
end

---@param dest string
---@return string?, string?, string?
local function parse_md_dest(dest)
  dest = vim.trim(dest)
  if dest:match('^https?://') or dest:match('^mailto:') then
    return
  end
  if dest:match('^file://') then
    dest = dest:gsub('^file://', '')
  end
  local path, frag = dest:match('^([^#]+)#?(.*)$')
  if not path or path == '' then
    return
  end
  path = path:gsub('%?.*$', '')
  local heading = frag ~= '' and frag or nil
  return path, heading, nil
end

---@param line string
---@param row integer 0-indexed
---@return markdown_xanadu.Link[]
local function wiki_links_in_line(line, row)
  if line:find('`', 1, true) then
    line = line:gsub('`[^`]*`', '')
  end
  local links = {}
  local start = 1
  while true do
    local s, e, bang, inner = line:find(WIKI_INNER, start)
    if not s then
      break
    end
    local p, h, b = parse_wiki_inner_text(inner)
    if p then
      links[#links + 1] = {
        kind = bang == '!' and 'embed' or 'link',
        raw = line:sub(s, e),
        path = p,
        heading = h,
        block_id = b,
        range = { row, s - 1, row, e },
      }
    end
    start = e + 1
  end
  return links
end

---@param line string
---@param row integer
---@return markdown_xanadu.Link[]
local function md_links_in_line(line, row)
  if line:find('`', 1, true) then
    -- ponytail: skip lines with backticks rather than full code-span AST
    local stripped = line:gsub('`[^`]*`', '')
    line = stripped
  end
  local links = {}
  local start = 1
  while true do
    local s, e, text, dest = line:find(MD_LINK_RE, start)
    if not s then
      break
    end
    local path, heading, block = parse_md_dest(dest)
    if path then
      local kind = 'link'
      if text:match('^!') or line:sub(math.max(1, s - 1), s - 1) == '!' then
        kind = 'embed'
      end
      links[#links + 1] = {
        kind = kind,
        raw = line:sub(s, e),
        path = path,
        heading = heading,
        block_id = block,
        range = { row, s - 1, row, e },
      }
    end
    start = e + 1
  end
  return links
end

---@param bufnr integer
---@return markdown_xanadu.Link[]
function M.links_in_buffer(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local links = {}
  local in_fence = false
  for row, line in ipairs(lines) do
    if line:match('^```') then
      in_fence = not in_fence
    elseif not in_fence then
      vim.list_extend(links, wiki_links_in_line(line, row - 1))
      vim.list_extend(links, md_links_in_line(line, row - 1))
    end
  end
  return links
end

---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return markdown_xanadu.Link?
function M.link_at_cursor(bufnr, row, col)
  bufnr = bufnr or 0
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  local in_fence = false
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
  for _, l in ipairs(lines) do
    if l:match('^```') then
      in_fence = not in_fence
    end
  end
  if in_fence then
    return
  end

  local candidates = {}
  vim.list_extend(candidates, wiki_links_in_line(line, row))
  vim.list_extend(candidates, md_links_in_line(line, row))

  for _, link in ipairs(candidates) do
    local sr, sc, er, ec = link.range[1], link.range[2], link.range[3], link.range[4]
    if row == sr and col >= sc and (row < er or col < ec) then
      return link
    end
  end
end

---@param link markdown_xanadu.Link
---@return string
function M.link_label(link)
  local label = link.path
  if link.heading then
    label = label .. '#' .. link.heading
  end
  if link.block_id then
    label = label .. '^' .. link.block_id
  end
  return label
end

---@param link markdown_xanadu.Link
---@return string
function M.link_id(link)
  return ('%s:%d:%d:%s'):format(link.kind, link.range[1], link.range[2], M.link_label(link))
end

return M
