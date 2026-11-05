local M = {}

---@param bufnr integer
---@param hunks? table[]
---@return conform.Range[]
function M.ranges(bufnr, hunks)
  if hunks == nil then
    if not pcall(require, 'gitsigns') then
      return {}
    end
    hunks = require('gitsigns').get_hunks(bufnr)
  end
  if not hunks or #hunks == 0 then
    return {}
  end

  local out = {}
  for _, hunk in ipairs(hunks) do
    local added = hunk.added
    if added and added.count and added.count > 0 and added.start then
      local start_line = added.start
      local end_line = added.start + added.count - 1
      local line = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1] or ''
      out[#out + 1] = {
        start = { start_line, 0 },
        ['end'] = { end_line, #line },
      }
    end
  end

  return out
end

---@param bufnr integer
---@param hunks? table[]
---@return conform.Range?
function M.range(bufnr, hunks)
  local ranges = M.ranges(bufnr, hunks)
  if #ranges == 0 then
    return nil
  end
  return {
    start = ranges[1].start,
    ['end'] = ranges[#ranges]['end'],
  }
end

--- Format each git hunk range bottom-to-top so line edits in lower hunks do not shift upper hunks.
---@param bufnr integer
---@param opts conform.FormatOpts
---@return boolean handled
function M.format(bufnr, opts)
  local ranges = M.ranges(bufnr)
  if #ranges == 0 then
    return false
  end

  local conform = require('conform')
  for i = #ranges, 1, -1 do
    local range = ranges[i]
    if bufnr == 0 then
      bufnr = vim.api.nvim_get_current_buf()
    end
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local end_line = math.min(range['end'][1], line_count)
    local line = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1] or ''
    conform.format(vim.tbl_deep_extend('force', opts, {
      bufnr = bufnr,
      range = {
        start = { math.min(range.start[1], end_line), 0 },
        ['end'] = { end_line, #line },
      },
      async = false,
      undojoin = i < #ranges,
    }))
  end
  return true
end

return M
