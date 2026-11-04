local M = {}

---@param bufnr integer
---@return conform.Range?
function M.range(bufnr)
  if not pcall(require, 'gitsigns') then
    return nil
  end
  local hunks = require('gitsigns').get_hunks(bufnr)
  if not hunks or #hunks == 0 then
    return nil
  end

  local start_line, end_line
  for _, hunk in ipairs(hunks) do
    local added = hunk.added
    if added and added.count and added.count > 0 and added.start then
      local h_end = added.start + added.count - 1
      start_line = start_line and math.min(start_line, added.start) or added.start
      end_line = end_line and math.max(end_line, h_end) or h_end
    end
  end

  if not start_line then
    return nil
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1] or ''
  return {
    start = { start_line, 0 },
    ['end'] = { end_line, #line },
  }
end

--- Format only git hunks when possible; whole-buffer format is left to conform on save.
---@param bufnr integer
---@param opts conform.FormatOpts
---@return boolean handled
function M.format(bufnr, opts)
  local range = M.range(bufnr)
  if not range then
    return false
  end

  require('conform').format(vim.tbl_deep_extend('force', opts, {
    bufnr = bufnr,
    range = range,
    async = false,
  }))
  return true
end

return M
