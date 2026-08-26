local parse = require('markdown_xanadu.parse')

local M = {}

local ns = vim.api.nvim_create_namespace('markdown_xanadu.highlight')

---@param bufnr integer
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

---@param bufnr integer
function M.apply(bufnr)
  M.clear(bufnr)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local link = parse.link_at_cursor(bufnr, row - 1, col - 1)
  if not link then
    return
  end
  local sr, sc, er, ec = link.range[1], link.range[2], link.range[3], link.range[4]
  vim.api.nvim_buf_add_highlight(bufnr, ns, 'LspReferenceRead', sr, sc, ec)
end

---@param bufnr integer
function M.setup(bufnr)
  local group = vim.api.nvim_create_augroup('markdown_xanadu.highlight.' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      M.apply(bufnr)
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufLeave' }, {
    group = group,
    buffer = bufnr,
    callback = function()
      M.clear(bufnr)
    end,
  })
end

return M
