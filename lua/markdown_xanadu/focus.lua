local registry = require('markdown_xanadu.registry')

local M = {}

---@param bufnr integer
---@param main_win integer
---@return markdown_xanadu.Entry?
function M.active_entry(bufnr, main_win)
  if not (main_win and vim.api.nvim_win_is_valid(main_win)) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(main_win)[1]
  return registry.entry_at_line(bufnr, row)
end

---@param bufnr integer
---@param main_win integer
---@return string?
function M.active_id(bufnr, main_win)
  local entry = M.active_entry(bufnr, main_win)
  return entry and entry.id or nil
end

return M
