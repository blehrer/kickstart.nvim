local parse = require('markdown_xanadu.parse')
local resolve = require('markdown_xanadu.resolve')

local M = {}

---@class markdown_xanadu.Entry
---@field id string
---@field link markdown_xanadu.Link
---@field label string
---@field resolved? { file: string, line: integer, col: integer, exists: boolean }
---@field open boolean
---@field embed_win? integer

---@type table<integer, markdown_xanadu.Entry[]>
local by_buf = {}

---@param bufnr integer
---@return markdown_xanadu.Entry[]
function M.scan(bufnr)
  local links = parse.links_in_buffer(bufnr)
  local entries = {}
  for _, link in ipairs(links) do
    local resolved = resolve.resolve(bufnr, link)
    entries[#entries + 1] = {
      id = parse.link_id(link),
      link = link,
      label = parse.link_label(link),
      resolved = resolved,
      open = false,
    }
  end
  by_buf[bufnr] = entries
  return entries
end

---@param bufnr integer
---@return markdown_xanadu.Entry[]
function M.get(bufnr)
  if not by_buf[bufnr] then
    return M.scan(bufnr)
  end
  return by_buf[bufnr]
end

---@param bufnr integer
---@param line integer 1-indexed
---@return markdown_xanadu.Entry?
function M.entry_at_line(bufnr, line)
  for _, e in ipairs(M.get(bufnr)) do
    if e.link.range[1] + 1 == line then
      return e
    end
  end
end

---@param bufnr integer
---@param id string
---@return markdown_xanadu.Entry?
function M.find(bufnr, id)
  for _, e in ipairs(M.get(bufnr)) do
    if e.id == id then
      return e
    end
  end
end

---@param bufnr integer
function M.clear(bufnr)
  by_buf[bufnr] = nil
end

---@param bufnr integer
---@param entry markdown_xanadu.Entry
---@param open boolean
---@param embed_win? integer
function M.set_open(bufnr, entry, open, embed_win)
  entry.open = open
  entry.embed_win = embed_win
end

---@param bufnr integer
---@return markdown_xanadu.Entry[]
function M.open_entries(bufnr)
  local out = {}
  for _, e in ipairs(M.get(bufnr)) do
    if e.open then
      out[#out + 1] = e
    end
  end
  return out
end

return M
